open! Core
open! Async
open Cmdliner

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
    let open Danbooru_lib in
    let open Deferred.Or_error.Let_syntax in
    Pool.get pool_id ~config
    >>= Pool.save_all ~config ~naming_scheme
  in
  Term.(pure main $ Config.term $ pool_id $ naming_scheme),
  Term.info "pool"
    ~doc:"download a pool of Danbooru posts"
    ~sdocs:Manpage.s_common_options
    ~man:[ `S Manpage.s_authors
         ; `P "%%PKG_AUTHORS%%" ]
;;

let post_cmd : async_cmd =
  let ids =
    Arg.info []
      ~docv:"ID"
    |> Arg.(pos_all int [])
    |> Arg.non_empty
  in
  let main (config : Danbooru_lib.Config.t) ids =
    let open Danbooru_lib in
    Downloader.download_posts config.downloader ids ~naming_scheme:`Md5
  in
  Term.(pure main $ Config.term $ ids),
  Term.info "post"
    ~doc:"download Danbooru posts by ID"
    ~sdocs:Manpage.s_common_options
    ~man:[ `S Manpage.s_authors
         ; `P "%%PKG_AUTHORS%%" ]
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
    let open Danbooru_lib in
    let open Deferred.Or_error.Let_syntax in
    Tags.search tags ~config
    >>= Deferred.Or_error.List.iter ~f:(Post.download ~basename:`Md5 ~config)
  in
  Term.(pure main $ Config.term $ tags),
  Term.info "tags"
    ~doc:"download Danbooru posts by tag"
    ~sdocs:Manpage.s_common_options
    ~man:[ `S Manpage.s_authors
         ; `P "%%PKG_AUTHORS%%" ]
;;

let async_cmd async =
  let run (config : Danbooru_lib.Config.t) (async : unit Deferred.Or_error.t) =
    let deferred =
      let%bind result = async in
        (* this feels like a bit of a stopgap, but actually getting "all
           writers" to flush is non-trivial using [Cmdliner] instead of
           [Core.Command] *)
      let%bind () = Log.flushed config.log in
      let%bind () = Log.close   config.log in
      return result
    in
    match Thread_safe.block_on_async_exn (fun () -> deferred) with
    | Ok ()   -> `Ok ()
    | Error e -> `Error (false, Error.to_string_hum e)
  in
  Term.(ret (pure run $ Config.term $ async))
;;

let name    = "%%NAME%%"
let version = "%%VERSION%%"

let main_cmd =
  Term.(ret (pure (`Help (`Auto, None)))),
  Term.info name
    ~doc:"Danbooru download tool"
    ~sdocs:Manpage.s_common_options
    ~version
    ~man:[ `S Manpage.s_authors
         ; `P "%%PKG_AUTHORS%%" ]
;;

let () =
  [ pool_cmd
  ; post_cmd
  ; tags_cmd ]
  |> List.map ~f:(Tuple2.map_fst ~f:async_cmd)
  |> Term.eval_choice main_cmd
  |> Term.exit
;;

let _ = 3
