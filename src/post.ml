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

let of_json json =
  let open Or_error.Let_syntax in
  let%map id       = Json.(json |> property ~key:"id"       >>= to_int)
  and     md5      = Json.(json |> property ~key:"md5"      >>= to_string)
  and     file_url = Json.(json |> property ~key:"file_url" >>= to_string)
  and     file_ext = Json.(json |> property ~key:"file_ext" >>= to_string)
  in
  { id; file_url; md5; file_ext }
;;

let get id =
  let%map json =
    let path = sprintf "/posts/%d.json" id in
    Danbooru.make_uri () ~path
    |> Http.get_json
  in
  let json = Or_error.tag_arg json "get" () (fun () -> [%message "" ~post_id:(id : int)]) in
  Or_error.bind json ~f:of_json
;;

let save { file_ext; file_url; id = _; md5 = _ } ~basename =
  let filename = basename ^ "." ^ file_ext in
  let uri = Danbooru.make_uri () ~path:file_url in
  Http.download uri ~filename
;;

let download t ~basename =
  let basename =
    match basename with
    | `Md5        -> md5 t
    | `Basename b -> b
  in
  let%map result = save t ~basename in
  Log.Global.info "%s %d" t.md5 t.id;
  result
;;

let page_size = 20

let search ~tags =
  let tags = String.concat tags ~sep:" " in
  let%bind post_count =
    let uri =
      Danbooru.make_uri ()
        ~path:"/counts/posts.json"
        ~query:[ ("tags", [ tags ]) ]
    in
    let%map json = Http.get_json uri in
    Json.(json >>= property ~key:"counts" >>= property ~key:"posts" >>= to_int)
  in
  match post_count with
  | Error _ as err -> return err
  | Ok post_count ->
    let page_count = Int.round_up post_count ~to_multiple_of:page_size / page_size in
    let base_uri =
      Danbooru.make_uri ()
        ~path:"/posts.json"
        ~query:[ ("tags", [ tags ]); ("limit", [ Int.to_string page_size ]) ]
    in
    List.range 1 page_count ~stop:`inclusive
    |> List.map ~f:(fun page ->
      let uri = Uri.add_query_param' base_uri ("page", Int.to_string page) in
      let%map json = Http.get_json uri in
      let open Or_error.Let_syntax in
      let%bind posts = json >>= Json.to_list in
      List.map posts ~f:of_json
      |> Or_error.all
    )
    |> Deferred.Or_error.all
    |> Deferred.Or_error.map ~f:List.concat
;;
