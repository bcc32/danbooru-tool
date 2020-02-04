open! Core
open! Async

type t =
  { id : int
  ; post_count : int
  ; post_ids : int list
  }
[@@deriving sexp]

let get id ~(config : Config.t) =
  let json =
    let path = sprintf "/pools/%d.json" id in
    Danbooru.make_uri () ~path |> Http.get_json config.http
  in
  let%map json = json in
  let%bind.Or_error json = json in
  let of_json =
    [%map_open.Json.Of_json
      let post_ids = "post_ids" @. list int
      and post_count =
        let open Json.Of_json in
        "post_count" @. int
      in
      { id; post_count; post_ids }]
  in
  Json.Of_json.run of_json json
;;

let save_all t ~(config : Config.t) ~naming_scheme =
  let%map result =
    Downloader.download_posts config.downloader t.post_ids ~naming_scheme
  in
  Or_error.tag_arg result "Pool.save_all" () (fun () ->
    [%message "error downloading pool" ~pool_id:(t.id : int)])
;;
