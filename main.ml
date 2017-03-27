open! Core
open! Async
open! Danbooru_tool

let login_flag   = Command.Param.(flag "-login"   (optional string) ~doc:"string Danbooru username")
let api_key_flag = Command.Param.(flag "-api-key" (optional string) ~doc:"string Danbooru API key")

let danbooru_params =
  let set_auth (login, api_key) =
    Option.both login api_key
    |> Option.iter ~f:(fun (login, api_key) ->
      Auth.t := Some Auth.{ login; api_key })
  in
  Command.Param.(
    both login_flag api_key_flag
    |> map ~f:set_auth
  )

let pool_command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and md5 =
      flag "-md5" no_arg
        ~doc:" save to filename with MD5 hash (default is post index)"
    and max_connections =
      flag "-max-connections" (optional_with_default 100 int)
        ~doc:"int maximum number of simultaneous connections (default is 100)"
    and () = danbooru_params
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
    and () = danbooru_params
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
