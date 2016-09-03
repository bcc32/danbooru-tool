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

let post_data id =
  "http://danbooru.donmai.us/posts/" ^ Int.to_string id ^ ".json"
  |> Uri.of_string
  |> Http.get_json
;;

let basename_of_file_url url =
  String.rsplit2 url ~on:'/'
  |> function
  | Some (_, basename) -> Ok basename
  | None -> Or_error.error_string "no / in file url"
;;

let download_post id =
  let%bind post_json = post_data id in
  match post_json with
  | Ok json ->
    begin match Json.property_s json ~name:"file_url" with
    | Ok file_url ->
      let filename = basename_of_file_url file_url in
      let url = "http://danbooru.donmai.us" ^ file_url |> Uri.of_string in
      let%bind contents = Http.get url in
      begin match Or_error.both filename contents with
      | Ok (name, contents) -> Writer.with_file name ~f:(fun w -> Writer.write w contents; Writer.close w)
      | Error e -> eprintf !"%{sexp: Error.t}\n" e; Deferred.unit
      end
    | Error e -> eprintf !"%{sexp: Error.t}\n" e; Deferred.unit
    end
  | Error e -> eprintf !"%{sexp: Error.t}\n" e; Deferred.unit
;;

let pool_command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int) in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind posts = pool_posts pool_id in
      Pipe.of_list posts
      |> Pipe.iter ~f:download_post
      >>| Or_error.return
  end
;;

let post_command =
  Command.async' ~summary:"Download Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open (id, ids) = anon ("id" %: int |> non_empty_sequence) in
    fun () ->
      List.map (id::ids) ~f:download_post
      |> Deferred.all_unit
  end
;;

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ]
;;

let () = Command.run command
