open! Core.Std
open! Async.Std

let pool_data id =
  "http://danbooru.donmai.us/pools/" ^ Int.to_string id ^ ".json"
  |> Uri.of_string
  |> Http.get_json
;;

let string_of_body =
  function
  | `Empty  -> Deferred.return ""
  | `Pipe r ->
    let%map strings = Pipe.read_all r >>| Queue.to_list in
    String.concat strings
  | `String s -> Deferred.return s
  | `Strings s -> Deferred.return (String.concat s)
;;

let read_posts json =
  match json with
  | `Assoc mappings ->
    List.Assoc.find mappings "post_ids"
    |> begin function
    | Some (`String ids) -> String.split ids ~on:' ' |> List.map ~f:Int.of_string |> Or_error.return
    | Some _ -> Or_error.error_string "[post_ids] value is not a string"
    | None   -> Or_error.error_string "no [post_ids] field"
    end
  | _ -> Or_error.error_string "not a JSON object"
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

let read_file_url json =
  match json with
  | `Assoc mappings ->
    List.Assoc.find mappings "file_url"
    |> begin function
    | Some (`String file_url) -> Ok file_url
    | Some _ -> Or_error.error_string "[file_url] value is not a string"
    | None   -> Or_error.error_string "no [file_url] field"
    end
  | _ -> Or_error.error_string "not a JSON object"
;;

let basename_of_file_url url =
  String.rsplit2 url ~on:'/'
  |> function
  | Some (_, basename) -> Ok basename
  | None -> Or_error.error_string "no / in file url"

let download_post id =
  let%bind post_json = id |> post_data in
  match post_json with
  | Ok json ->
    begin match read_file_url json with
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

let command =
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

let () = Command.run command
