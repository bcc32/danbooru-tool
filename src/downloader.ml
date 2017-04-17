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
  let open Deferred.Or_error.Let_syntax in
  let%bind post = get_post () in
  let%map result = save_post post in
  Log.Global.info "%s %d" post.md5 post.id;
  result
;;

let download_posts ids ~naming_scheme =
  let deferreds =
    match naming_scheme with
    | `Md5 -> List.map ids ~f:(download ~basename:`Md5)
    | `Sequential ->
      let digits = List.length ids |> Int.to_string |> String.length in
      let pad = sprintf "%0*d" digits in
      List.mapi ids ~f:(fun i -> download ~basename:(`Basename (pad i)))
  in
  Deferred.Or_error.all_ignore deferreds
;;
