open! Core
open! Async

type t =
  { id        : int
  ; file_ext  : string
  ; file_url  : string
  ; md5       : string
  }
[@@deriving fields, sexp]

let of_json json =
  let open Or_error.Let_syntax in
  let%map id       = Json.(json |> property ~key:"id"       >>= to_int)
  and     md5      = Json.(json |> property ~key:"md5"      >>= to_string)
  and     file_url = Json.(json |> property ~key:"file_url" >>= to_string)
  and     file_ext = Json.(json |> property ~key:"file_ext" >>= to_string)
  in
  { id; file_url; md5; file_ext }
;;

let get id ~http =
  let%map json =
    let path = sprintf "/posts/%d.json" id in
    Danbooru.make_uri () ~path
    |> Http.get_json http
  in
  let json = Or_error.tag_arg json "get" () (fun () -> [%message "" ~post_id:(id : int)]) in
  Or_error.bind json ~f:of_json
;;

let save { file_ext; file_url; id = _; md5 = _ } ~http ~basename =
  let filename = basename ^ "." ^ file_ext in
  let uri = Danbooru.resolve (Uri.of_string file_url) in
  Http.download http uri ~filename
;;

let download t ~http ~basename =
  let basename =
    match basename with
    | `Md5        -> md5 t
    | `Basename b -> b
  in
  let%map result = save t ~http ~basename in
  Log.Global.info "%s %d" t.md5 t.id;
  result
;;
