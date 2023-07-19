open! Core
open! Async
open Cmdliner

let dump_only =
  Arg.info
    [ "dump" ]
    ~docs:Manpage.s_options
    ~doc:"Dump post info a s-expressions instead of downloading."
  |> Arg.flag
  |> Arg.value
;;

(* TODO: Factor out this async_main logic. *)
let async_cmd (async : unit Deferred.Or_error.t Term.t) : unit Term.t =
  let run (danbooru : (module Danbooru_lib.Danbooru.S)) (async : unit Deferred.Or_error.t)
    =
    let open (val danbooru) in
    let deferred =
      let%bind result = async in
      (* this feels like a bit of a stopgap, but actually getting "all
         writers" to flush is non-trivial using [Cmdliner] instead of
         [Core.Command] *)
      let%bind () = Log.flushed Config.log in
      let%bind () = Log.close Config.log in
      return result
    in
    match Thread_safe.block_on_async_exn (fun () -> deferred) with
    | Ok () -> `Ok ()
    | Error e -> `Error (false, Error.to_string_hum e)
  in
  Term.(ret (const run $ Config.term $ async))
;;

let pool_cmd =
  let pool_id = Arg.info [] ~docv:"ID" |> Arg.(pos 0 (some int) None) |> Arg.required in
  let naming_scheme =
    let of_bool = function
      | true -> `Md5
      | false -> `Sequential
    in
    Arg.info [ "md5" ] ~doc:"Use MD5 hash as file basename (default is post index)"
    |> Arg.flag
    |> Arg.value
    |> Term.(app (const of_bool))
  in
  let main (danbooru : (module Danbooru_lib.Danbooru.S)) pool_id naming_scheme =
    let open (val danbooru) in
    let open Deferred.Or_error.Let_syntax in
    Pool.get pool_id >>= Pool.save_all ~naming_scheme
  in
  Cmd.v
    (Cmd.info
       "pool"
       ~doc:"download a pool of Danbooru posts"
       ~sdocs:Manpage.s_common_options
       ~man:[ `S Manpage.s_authors; `P "%%PKG_AUTHORS%%" ])
    (Term.(const main $ Config.term $ pool_id $ naming_scheme) |> async_cmd)
;;

let post_cmd =
  let ids = Arg.info [] ~docv:"ID" |> Arg.(pos_all int []) |> Arg.non_empty in
  let main (danbooru : (module Danbooru_lib.Danbooru.S)) ids =
    let open (val danbooru) in
    Downloader.download_posts ids ~naming_scheme:`Md5
  in
  Cmd.v
    (Cmd.info
       "post"
       ~doc:"download Danbooru posts by ID"
       ~sdocs:Manpage.s_common_options
       ~man:[ `S Manpage.s_authors; `P "%%PKG_AUTHORS%%" ])
    (Term.(const main $ Config.term $ ids) |> async_cmd)
;;

let tags_cmd =
  let tags =
    (* allow user to enter multiple tags in single arg with spaces *)
    let normalize tags = List.concat_map tags ~f:(String.split ~on:' ') in
    Arg.info [] ~docv:"TAG"
    |> Arg.(pos_all string [])
    |> Arg.non_empty
    |> Term.(app (const normalize))
  in
  let main (danbooru : (module Danbooru_lib.Danbooru.S)) dump_only tags =
    let open (val danbooru) in
    Monitor.try_with_or_error (fun () ->
      Post.search tags
      |> Pipe.iter ~f:(fun post ->
        if dump_only
        then (
          print_s [%sexp (post : Post.t)];
          return ())
        else Post.download post ~basename:`Md5 >>| ok_exn))
  in
  Cmd.v
    (Cmd.info
       "tags"
       ~doc:"download Danbooru posts by tag"
       ~sdocs:Manpage.s_common_options
       ~man:[ `S Manpage.s_authors; `P "%%PKG_AUTHORS%%" ])
    (Term.(const main $ Config.term $ dump_only $ tags) |> async_cmd)
;;

let tree_cmd =
  let roots =
    (* allow user to enter multiple tags in single arg with spaces *)
    Arg.info [] ~docv:"ROOT" |> Arg.(pos_all int []) |> Arg.non_empty
  in
  let main (danbooru : (module Danbooru_lib.Danbooru.S)) roots =
    let open (val danbooru) in
    let open Deferred.Or_error.Let_syntax in
    Deferred.Or_error.List.iter roots ~how:`Sequential ~f:(fun root ->
      let%bind tree = Tree.get root in
      Tree.save_all tree)
  in
  Cmd.v
    (Cmd.info
       "tree"
       ~doc:"download Danbooru posts in a tree"
       ~sdocs:Manpage.s_common_options
       ~man:[ `S Manpage.s_authors; `P "%%PKG_AUTHORS%%" ])
    (Term.(const main $ Config.term $ roots) |> async_cmd)
;;

let name = "%%NAME%%"
let version = "%%VERSION%%"

let () =
  [ pool_cmd; post_cmd; tags_cmd; tree_cmd ]
  |> Cmd.group
       ~default:Term.(ret (const (`Help (`Auto, None))))
       (Cmd.info
          name
          ~doc:"Danbooru download tool"
          ~sdocs:Manpage.s_common_options
          ~version
          ~man:[ `S Manpage.s_authors; `P "%%PKG_AUTHORS%%" ])
  |> Cmd.eval
  |> Core.exit
;;
