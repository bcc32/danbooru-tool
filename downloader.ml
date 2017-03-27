open! Core
open! Async

let download id ~throttle ~basename =
  let get_post () =
    let%map post = Rate_limiter.enqueue' throttle Post.get id in
    Or_error.tag_arg post "download" ()
      (fun () -> [%message "error getting post data" ~post_id:(id : int)])
  in
  let save_post post =
    let%map result = Rate_limiter.enqueue' throttle (Post.download ~basename) post in
    Or_error.tag_arg result "download" ()
      (fun () -> [%message "error downloading image" ~post_id:(id : int)])
  in
  Deferred.Or_error.(get_post () >>= save_post)
;;

let download_posts ids ~max_connections ~naming_scheme =
  let digits = List.length ids |> Int.to_string |> String.length in
  let pad n =
    let n = Int.to_string n in
    let padding = digits - String.length n in
    let buf = String.create digits in
    String.fill buf '0' ~pos:0 ~len:padding;
    String.blit ~src:n ~src_pos:0 ~dst:buf ~dst_pos:padding ~len:(String.length n);
    buf
  in
  let throttle = Rate_limiter.create_exn max_connections in
  let deferreds =
    match naming_scheme with
    | `Md5 -> List.map ids ~f:(download ~throttle ~basename:`Md5)
    | `Sequential ->
      List.mapi ids ~f:(fun i -> download ~throttle ~basename:(`Basename (pad i)))
  in
  Deferred.Or_error.all_ignore deferreds
;;
