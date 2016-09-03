open! Core.Std
open! Async.Std

type t =
  { id        : int
  ; file_url  : string
  ; md5       : string
  ; extension : string
  }
  [@@deriving fields]

let filename_extension filename =
  match filename |> Filename.split_extension |> snd with
  | Some ext -> Ok ext
  | None     -> Or_error.error_s [%message "no extension" (filename : string)]

let get id =
  let%map json =
    "http://danbooru.donmai.us/posts/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
    |> Http.get_json
  in
  let open Or_error.Let_syntax in
  let%bind json = json in
  let field name = Json.property_s json ~name in
  let%bind md5 = field "md5"
  and file_url = field "file_url" in
  let%map extension = filename_extension file_url in
  Fields.create ~id ~file_url ~md5 ~extension
;;

let save { extension; file_url; id = _; md5 = _ } ~basename =
  let filename = basename ^ "." ^ extension in
  let open Deferred.Or_error.Let_syntax in
  let%bind url =
    Or_error.try_with (fun () ->
      "http://danbooru.donmai.us" ^ file_url |> Uri.of_string)
    |> return
  in
  Http.download url ~filename
;;
