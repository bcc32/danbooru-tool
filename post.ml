open! Core.Std
open! Async.Std

type t =
  { id        : int
  ; file_url  : string
  ; md5       : string
  ; extension : string
  }
[@@deriving fields]
;;

let get id =
  let%map json =
    "http://danbooru.donmai.us/posts/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
    |> Http.get_json
  in
  let open Or_error.Let_syntax in
  let open Yojson.Basic.Util in
  let%bind json = json in
  let%bind md5      = Or_error.try_with (fun () -> member "md5"      json |> to_string)
  and      file_url = Or_error.try_with (fun () -> member "file_url" json |> to_string) in
  let%map extension =
    match file_url |> Filename.split_extension |> snd with
    | Some ext -> Ok ext
    | None -> Or_error.error_s [%message "no extension" (file_url : string)]
  in
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

let download t ~basename =
  let basename =
    match basename with
    | `Md5        -> md5 t
    | `Basename b -> b
  in
  save t ~basename
;;
