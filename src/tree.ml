open! Core
open! Async

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

let rec get id ~(config : Config.t) =
  let json =
    let path = sprintf "/posts/%d.json" id in
    Danbooru.make_uri () ~path ~query:[ "only", [ "children[id]" ] ]
    |> Http.get_json config.http
  in
  let open Deferred.Or_error.Let_syntax in
  let%bind json = json in
  let%bind child_ids = read_child_ids json |> Deferred.return in
  let%bind children = Deferred.Or_error.List.map child_ids ~f:(get ~config) in
  return { id; children }
;;

let all_post_ids t =
  let rec loop t accum =
    t.id :: List.fold t.children ~init:accum ~f:(fun accum child -> loop child accum)
  in
  loop t []
;;

let save_all t ~(config : Config.t) =
  let%map result =
    Downloader.download_posts config.downloader (all_post_ids t) ~naming_scheme:`Md5
  in
  Or_error.tag_arg result "Tree.save_all" () (fun () ->
    [%message "error downloading tree" ~root:(t.id : int)])
;;
