open! Core
open! Async
open Cmdliner
open Danbooru_lib

let output_dir =
  Arg.info [ "d"; "output-dir" ]
    ~docs:Manpage.s_common_options
    ~docv:"DIR"
    ~doc:"Save downloaded image files to directory $(docv)."
  |> Arg.(opt string ".")
  |> Arg.value
;;

let log_level =
  let of_list verbosity =
    match verbosity with
    | []  -> `Error
    | [_] -> `Info
    | _   -> `Debug
  in
  let flag_count =
    Arg.info [ "v"; "verbose" ]
      ~docs:Manpage.s_common_options
      ~doc:"Increase the level of verbosity."
    |> Arg.flag_all
    |> Arg.value
  in
  Term.(pure of_list $ flag_count)
;;

let auth =
  let auth_conv =
    let parse s =
      match Auth.of_string s with
      | auth -> Ok auth
      | exception _ -> Error (`Msg "malformed auth string")
    in
    Arg.conv (parse, Auth.pp)
  in
  Arg.info [ "auth" ]
    ~env:(Arg.env_var "DANBOORU_AUTH"
            ~doc:"User and API key used to access Danbooru API.")
    ~docs:Manpage.s_common_options
    ~docv:"USER:API_KEY"
    ~doc:"Set the user and API key used to access the Danbooru API."
  |> Arg.(opt (some auth_conv) None)
  |> Arg.value
;;

let max_concurrent_jobs =
  Arg.info [ "max-connections" ]
    ~docs:Manpage.s_common_options
    ~docv:"INT"
    ~doc:"Set the maximum number of simultaneous connections."
  |> Arg.(opt int 5)
  |> Arg.value
;;

let config =
  let make_config output_dir log_level auth max_concurrent_jobs =
    Config.create
      ~output_dir
      ~log_level
      ~auth
      ~max_concurrent_jobs
  in
  Term.(pure make_config $ output_dir $ log_level $ auth $ max_concurrent_jobs)
;;

type async_cmd = unit Deferred.Or_error.t Term.t * Term.info

let pool_cmd : async_cmd =
  let pool_id =
    Arg.info []
      ~docv:"ID"
    |> Arg.(pos 0 (some int) None)
    |> Arg.required
  in
  let naming_scheme =
    let of_bool = function | true -> `Md5 | false -> `Sequential in
    Arg.info [ "md5" ]
      ~doc:"Use MD5 hash as file basename (default is post index)"
    |> Arg.flag
    |> Arg.value
    |> Term.(app (pure of_bool))
  in
  let main config pool_id naming_scheme =
    let open Deferred.Or_error.Let_syntax in
    let%bind pool = Pool.get pool_id ~config in
    Pool.save_all pool ~config ~naming_scheme
  in
  Term.(pure main $ config $ pool_id $ naming_scheme),
  Term.info "pool"
    ~doc:"download a pool of Danbooru posts"
    ~sdocs:Manpage.s_common_options
;;

let post_cmd : async_cmd =
  let ids =
    Arg.info []
      ~docv:"ID"
    |> Arg.(pos_all int [])
    |> Arg.non_empty
  in
  let main (config : Config.t) ids =
    Downloader.download_posts config.downloader ids ~naming_scheme:`Md5
  in
  Term.(pure main $ config $ ids),
  Term.info "post"
    ~doc:"download Danbooru posts by ID"
    ~sdocs:Manpage.s_common_options
;;

let tags_cmd : async_cmd =
  let tags =
    (* allow user to enter multiple tags in single arg with spaces *)
    let normalize tags = List.concat_map tags ~f:(String.split ~on:' ') in
    Arg.info []
      ~docv:"TAG"
    |> Arg.(pos_all string [])
    |> Arg.non_empty
    |> Term.(app (pure normalize))
  in
  let main config tags =
    let open Deferred.Or_error.Let_syntax in
    let%bind posts = Tags.search tags ~config in
    List.map posts ~f:(Post.download ~basename:`Md5 ~config)
    |> Deferred.Or_error.all_ignore
  in
  Term.(pure main $ config $ tags),
  Term.info "tags"
    ~doc:"download Danbooru posts by tag"
    ~sdocs:Manpage.s_common_options
;;

let async_cmd async =
  let run async =
    match Thread_safe.block_on_async (fun () -> async) with
    | Ok (Ok ())   -> `Ok ()
    | Ok (Error e) -> `Error (false, Error.to_string_hum e)
    | Error exn    -> `Error (false, Exn.to_string exn)
  in
  Term.(ret (pure run $ async))
;;

let name    = "danbooru-tool"
let version = "0.2.0"

let main_cmd =
  Term.(ret (pure (`Help (`Pager, None)))),
  Term.info name
    ~doc:"Danbooru download tool"
    ~sdocs:Manpage.s_common_options
    ~version
;;

let () =
  [ pool_cmd
  ; post_cmd
  ; tags_cmd ]
  |> List.map ~f:(Tuple2.map_fst ~f:async_cmd)
  |> Term.eval_choice main_cmd
  |> Term.exit
;;
