open! Core
open! Async

type t =
  { id : int
  ; post_count : int
  ; post_ids : int list
  }
[@@deriving sexp]

let read_posts json =
  let post_ids = Json.(json |> property ~key:"post_ids" >>= to_string) in
  Or_error.(post_ids >>| String.split ~on:' ' >>| List.map ~f:Int.of_string)
;;

let get id ~(config : Config.t) =
  let json =
    let path = sprintf "/pools/%d.json" id in
    Danbooru.make_uri () ~path |> Http.get_json config.http
  in
  let%map json = json in
  let open Or_error.Let_syntax in
  let%bind json = json in
  let%map post_ids = read_posts json
  and post_count = Json.(json |> property ~key:"post_count" >>= to_int) in
  { id; post_count; post_ids }
;;

let save_all t ~(config : Config.t) ~naming_scheme =
  let%map result =
    Downloader.download_posts config.downloader t.post_ids ~naming_scheme
  in
  Or_error.tag_arg result "Pool.save_all" () (fun () ->
    [%message "error downloading pool" ~pool_id:(t.id : int)])
;;
