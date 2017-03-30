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
    and () = Auth.param
    and () = Rate_limiter.param
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind pool = Pool.get pool_id in
      Pool.save_all pool ~naming_scheme:(if md5 then `Md5 else `Sequential)
  end
;;

let post_command =
  Command.async_or_error' ~summary:"Download Danbooru posts by ID" begin
    let open Command.Let_syntax in
    let%map_open ids = anon ("id" %: int |> non_empty_sequence_as_list)
    and () = Auth.param
    and () = Rate_limiter.param
    in
    fun () -> Downloader.download_posts ids ~naming_scheme:`Md5
  end
;;

let tags_command =
  Command.async_or_error' ~summary:"Download Danbooru posts by tag" begin
    let open Command.Let_syntax in
    let%map_open tags = anon ("tag" %: string |> sequence)
    and () = Auth.param
    and () = Rate_limiter.param
    in
    fun () ->
      (* allow user to enter mutliple tags in single arg with spaces *)
      let tags = List.concat_map tags ~f:(String.split ~on:' ') in
      let open Deferred.Or_error.Let_syntax in
      Post.search ~tags
      |> Deferred.Or_error.bind ~f:(fun posts ->
        List.map posts ~f:(Post.download ~basename:`Md5)
        |> Deferred.Or_error.all_ignore
      )
  end

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ; "tags", tags_command
    ]
;;

let () = Command.run command
