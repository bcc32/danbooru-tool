open! Core
open! Async

type t =
  { id : int
  ; file_ext : string
  ; file_url : string
  ; md5 : string
  }
[@@deriving fields, sexp]

let of_json json =
  let open Or_error.Let_syntax in
  let%map id = Json.(json |> property ~key:"id" >>= to_int)
  and md5 = Json.(json |> property ~key:"md5" >>= to_string)
  and file_url = Json.(json |> property ~key:"file_url" >>= to_string)
  and file_ext = Json.(json |> property ~key:"file_ext" >>= to_string) in
  { id; file_url; md5; file_ext }
;;

let get id ~log ~http =
  let json =
    let path = sprintf "/posts/%d.json" id in
    Danbooru.make_uri () ~path |> Http.get_json http
  in
  let%map json =
    Deferred.Or_error.tag_arg json "Post.get" id (fun id ->
      [%message "error getting post data" ~post_id:(id : int)])
  in
  let t = Or_error.(json >>= of_json) in
  if Or_error.is_ok t then Log.info log "post %d data" id;
  t
;;

let save t ~http ~basename =
  let filename = basename ^ "." ^ t.file_ext in
  let uri = Danbooru.resolve (Uri.of_string t.file_url) in
  let result = Http.download http uri ~filename in
  Deferred.Or_error.tag_arg result "Post.save" (t.id, filename) (fun (id, filename) ->
    [%message "error downloading post" ~post_id:(id : int) (filename : string)])
;;

let download t ~log ~http ~basename =
  let basename =
    match basename with
    | `Md5 -> md5 t
    | `Basename b -> b
  in
  let%map result = save t ~http ~basename in
  if Or_error.is_ok result then Log.info log "%s %d" t.md5 t.id;
  result
;;
