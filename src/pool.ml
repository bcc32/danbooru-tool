open! Core
open! Async
include Pool_intf

module Make (Config : Config.S) (Downloader : Downloader.S) = struct
  type t =
    { id : int
    ; post_count : int
    ; post_ids : int list
    }
  [@@deriving sexp]

  let read_posts json =
    Json.(
      json
      |> property ~key:"post_ids"
      >>= to_list
      >>= fun list -> List.map list ~f:to_int |> Or_error.all)
  ;;

  let get id =
    let json =
      let path = sprintf "/pools/%d.json" id in
      Config.Which_server.make_uri () ~path |> Http.get_json Config.http
    in
    let%map json = json in
    let open Or_error.Let_syntax in
    let%bind json = json in
    let%map post_ids = read_posts json
    and post_count = Json.(json |> property ~key:"post_count" >>= to_int) in
    { id; post_count; post_ids }
  ;;

  let save_all t ~naming_scheme =
    let%map result = Downloader.download_posts t.post_ids ~naming_scheme in
    Or_error.tag_arg result "Pool.save_all" () (fun () ->
      [%message "error downloading pool" ~pool_id:(t.id : int)])
  ;;
end
