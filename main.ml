open! Core.Std
open! Async.Std

let pool_data id =
  "http://danbooru.donmai.us/pools/" ^ Int.to_string id ^ ".json"
  |> Uri.of_string
  |> Http.get_json
;;

let read_posts json =
  let open Or_error.Let_syntax in
  let%map ids = Json.property_s json ~name:"post_ids" in
  String.split ids ~on:' '
  |> List.map ~f:Int.of_string
;;

let pool_posts id =
  let%map data = pool_data id in
  Or_error.bind data read_posts
;;

let download_post id ~basename =
  let open Deferred.Or_error.Let_syntax in
  let%bind post = Post.get id in
  let basename =
    match basename with
    | `Md5        -> Post.md5 post
    | `Basename b -> b
  in
  Post.save post ~basename
;;

let pool_command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and digits =
      flag "-n" ~doc:"digits save to sequential filenames" (optional int)
    in
    fun () ->
      let pad n d =
        let n = Int.to_string n in
        let len = d - String.length n in
        if len > 0
        then (String.make len '0' ^ n)
        else n
      in
      let basename =
        match digits with
        | None -> Fn.const `Md5
        | Some d ->
          fun n -> `Basename (pad n d)
      in
      let open Deferred.Or_error.Let_syntax in
      let%bind posts = pool_posts pool_id in
      List.mapi posts ~f:(fun n id -> download_post id ~basename:(basename n))
      |> Deferred.Or_error.all_ignore
  end
;;

let post_command =
  Command.async_or_error' ~summary:"Download Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open (id, ids) = anon ("id" %: int |> non_empty_sequence) in
    fun () ->
      List.map (id::ids) ~f:(download_post ~basename:`Md5)
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
