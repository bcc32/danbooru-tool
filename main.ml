open! Core
open! Async
open! Danbooru_tool

let max_connections_flag =
  Command.Param.(
    flag "-max-connections" (optional_with_default 5 int)
      ~doc:"int maximum number of simultaneous connections (default 5)"
  )
;;

let pool_command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and md5 =
      flag "-md5" no_arg
        ~doc:" save to filename with MD5 hash (default is post index)"
    and max_connections = max_connections_flag
    and () = Auth.param
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind pool = Pool.get pool_id in
      Pool.save_all pool ~naming_scheme:(if md5 then `Md5 else `Sequential) ~max_connections
  end
;;

let post_command =
  Command.async_or_error' ~summary:"Download Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open ids = anon ("id" %: int |> non_empty_sequence_as_list)
    and max_connections = max_connections_flag
    and () = Auth.param
    in
    fun () -> Downloader.download_posts ids ~max_connections ~naming_scheme:`Md5
  end
;;

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ]
;;

let () = Command.run command
