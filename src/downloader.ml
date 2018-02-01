open! Core
open! Async

type t =
  { http : Http.t
  }
[@@deriving fields]

let create http = { http }

let download { http } id ~basename =
  let get_post () =
    let%map post = Post.get id ~http in
    Or_error.tag_arg post "download" ()
      (fun () -> [%message "error getting post data" ~post_id:(id : int)])
  in
  let save_post post =
    let%map result = Post.download post ~http ~basename in
    Or_error.tag_arg result "download" ()
      (fun () -> [%message "error downloading image" ~post_id:(id : int)])
  in
  Deferred.Or_error.(get_post () >>= save_post)
;;

let download_posts t ids ~naming_scheme =
  let deferreds =
    match naming_scheme with
    | `Md5 -> List.map ids ~f:(download t ~basename:`Md5)
    | `Sequential ->
      let digits = List.length ids |> Int.to_string |> String.length in
      let pad = sprintf "%0*d" digits in
      List.mapi ids ~f:(fun i -> download t ~basename:(`Basename (pad i)))
  in
  Deferred.Or_error.all_ignore deferreds
;;
