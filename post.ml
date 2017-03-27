open! Core
open! Async

type t =
  { id        : int
  ; file_ext  : string
  ; file_url  : string
  ; md5       : string
  }
[@@deriving fields, sexp]
;;

let get id =
  let%map json =
    Danbooru.host ^ "/posts/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
    |> Http.get_json
  in
  let open Or_error.Let_syntax in
  let%bind json = json in
  let%map md5      = Json.(json |> property ~key:"md5"      >>= to_string)
  and     file_url = Json.(json |> property ~key:"file_url" >>= to_string)
  and     file_ext = Json.(json |> property ~key:"file_ext" >>= to_string)
  in
  { id; file_url; md5; file_ext }
;;

let save { file_ext; file_url; id = _; md5 = _ } ~basename =
  let filename = basename ^ "." ^ file_ext in
  let open Deferred.Or_error.Let_syntax in
  let%bind url =
    Or_error.try_with (fun () -> Danbooru.host ^ file_url |> Uri.of_string)
    |> Deferred.return
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
