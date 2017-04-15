open! Core
open! Async

let download id ~basename =
  let get_post () =
    let%map post = Post.get id in
    Or_error.tag_arg post "download" ()
      (fun () -> [%message "error getting post data" ~post_id:(id : int)])
  in
  let save_post post =
    let%map result = Post.download post ~basename in
    Or_error.tag_arg result "download" ()
      (fun () -> [%message "error downloading image" ~post_id:(id : int)])
  in
  Deferred.Or_error.(get_post () >>= save_post)
;;

let pad digits =
  sprintf "%0*d" digits
;;

let download_posts ids ~naming_scheme =
  let deferreds =
    match naming_scheme with
    | `Md5 -> List.map ids ~f:(download ~basename:`Md5)
    | `Sequential ->
      let digits = List.length ids |> Int.to_string |> String.length in
      List.mapi ids ~f:(fun i -> download ~basename:(`Basename (pad digits i)))
  in
  Deferred.Or_error.all_ignore deferreds
;;
