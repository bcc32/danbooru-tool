open! Core
open! Async
include Tree_intf

module Make (Config : Config.S) (Downloader : Downloader.S) = struct
  type t =
    { id : int
    ; children : t list
    }
  [@@deriving sexp]

  let read_child_ids json =
    let open Json in
    let%bind.Or_error children = json |> property ~key:"children" >>= to_list in
    List.map children ~f:(fun child -> property child ~key:"id" >>= to_int)
    |> Or_error.combine_errors
  ;;

  let rec get id =
    let json =
      let path = sprintf "/posts/%d.json" id in
      Config.Which_server.make_uri () ~path ~query:[ "only", [ "children[id]" ] ]
      |> Http.get_json Config.http
    in
    let open Deferred.Or_error.Let_syntax in
    let%bind json = json in
    let%bind child_ids = read_child_ids json |> Deferred.return in
    let%bind children = Deferred.Or_error.List.map child_ids ~f:get in
    return { id; children }
  ;;

  let all_post_ids t =
    let rec loop t accum =
      t.id :: List.fold t.children ~init:accum ~f:(fun accum child -> loop child accum)
    in
    loop t []
  ;;

  let save_all t =
    let%map result = Downloader.download_posts (all_post_ids t) ~naming_scheme:`Md5 in
    Or_error.tag_arg result "Tree.save_all" () (fun () ->
      [%message "error downloading tree" ~root:(t.id : int)])
  ;;
end
