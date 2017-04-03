open! Core
open! Async
open! Danbooru_tool

let global_flags = Command.Param.all_ignore [ Auth.param; Rate_limiter.param ]

let command_with_global_flags param =
  let param = Command.Param.(global_flags *> param) in
  Command.async_or_error' param
;;

let pool_command =
  let param =
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and md5 =
      flag "-md5" no_arg
        ~doc:" save to filename with MD5 hash (default is post index)"
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind pool = Pool.get pool_id in
      Pool.save_all pool ~naming_scheme:(if md5 then `Md5 else `Sequential)
  in
  command_with_global_flags param ~summary:"download a pool of Danbooru posts"
;;

let post_command =
  let param =
    let open Command.Let_syntax in
    let%map_open ids = anon ("id" %: int |> non_empty_sequence_as_list) in
    fun () -> Downloader.download_posts ids ~naming_scheme:`Md5
  in
  command_with_global_flags param ~summary:"download Danbooru posts by ID"
;;

let tags_command =
  let param =
    let open Command.Let_syntax in
    let%map_open tags = anon ("tag" %: string |> sequence) in
    fun () ->
      (* allow user to enter mutliple tags in single arg with spaces *)
      let tags = List.concat_map tags ~f:(String.split ~on:' ') in
      let open Deferred.Or_error.Let_syntax in
      let%bind posts = Post.search ~tags in
      List.map posts ~f:(Post.download ~basename:`Md5)
      |> Deferred.Or_error.all_ignore
  in
  command_with_global_flags param ~summary:"download Danbooru posts by tag"
;;

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ; "tags", tags_command
    ]
;;

let build_info = "danbooru-tool"
let version    = "0.1.0"

let () = Command.run command ~build_info ~version
