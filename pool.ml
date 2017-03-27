open! Core
open! Async

type t =
  { id         : int
  ; post_count : int
  ; post_ids   : int list
  }
[@@deriving fields]
;;

let read_posts json =
  let post_ids = Json.(json |> property ~key:"post_ids" >>= to_string) in
  Or_error.(
    post_ids
    >>| String.split ~on:' '
    >>| List.map ~f:Int.of_string)
;;

let get id =
  let json =
    "http://danbooru.donmai.us/pools/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
    |> Http.get_json
  in
  let%map json = json in
  let open Or_error.Let_syntax in
  let%bind json = json in
  let%map post_ids = read_posts json
  and post_count = Json.(json |> property ~key:"post_count" >>= to_int) in
  { id; post_count; post_ids }
;;

let save_all t ~naming_scheme ~max_connections =
  let%map result = Downloader.download_posts t.post_ids ~max_connections ~naming_scheme in
  Or_error.tag_arg result "Pool.save_all" ()
    (fun () -> [%message "error downloading pool" ~pool_id:(t.id : int)])
;;
