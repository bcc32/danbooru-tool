open! Core.Std
open! Async.Std

let pool_data id =
  let url =
    "http://danbooru.donmai.us/pools/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
  in
  Cohttp_async.Client.get url
  >>| fun (response, body) ->
  match response.status with
  | `OK -> Ok body
  | _   -> Or_error.error_string (Cohttp.Code.string_of_status response.status)
;;

let json_of_body body =
  let body =
    match body with
    | `Empty  -> Deferred.Or_error.error_string "empty body"
    | `Pipe r ->
      let%map strings = Pipe.read_all r >>| Queue.to_list in
      Ok (String.concat strings)
    | `String s -> Deferred.Or_error.return s
    | `Strings s -> Deferred.Or_error.return (String.concat s)
  in
  let open Deferred.Or_error.Let_syntax in
  let%map body = body in
  Yojson.Basic.from_string body
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
  let json = pool_data id >>=? json_of_body in
  let%map json = json in
  Or_error.(json >>= read_posts)
;;

let download_post id =
  failwith "Unimplemented"
;;

let command =
  Command.async_or_error' ~summary:"Download a pool of Danbooru posts" begin
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int) in
    fun () ->
      pool_posts pool_id
      >>|? List.iter ~f:download_post
  end
;;

let () = Command.run command
