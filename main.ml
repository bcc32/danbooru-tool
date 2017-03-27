open! Core
open! Async
open! Danbooru_tool

let pool_command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and md5 =
      flag "-md5" no_arg
        ~doc:" save to filename with MD5 hash (default is post index)"
    and max_connections =
      flag "-max-connections" (optional_with_default 5 int)
        ~doc:"int maximum number of simultaneous connections (default is 5)"
    and () = Auth.param
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind pool = Pool.get pool_id in
      Pool.save_all pool ~basename:(if md5 then `Md5 else `Numerical) ~max_connections
  end
;;

let post_command =
  Command.async_or_error' ~summary:"Download Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open ids = anon ("id" %: int |> non_empty_sequence_as_list)
    and () = Auth.param
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      List.map ids ~f:(fun id ->
        let%bind post = Post.get id in
        Post.download post ~basename:`Md5)
      |> Deferred.Or_error.all_ignore
  end
;;

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ]
;;

let () = Command.run command
