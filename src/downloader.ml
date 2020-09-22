open! Core
open! Async
include Downloader_intf

module Make (Config : Config.S) (Post : Post.S) = struct
  let download id ~basename =
    let open Deferred.Or_error.Let_syntax in
    let%bind post = Post.get id in
    Post.download post ~basename
  ;;

  let download_posts ids ~naming_scheme =
    Deferred.Or_error.all_unit
      (match naming_scheme with
       | `Md5 -> List.map ids ~f:(download ~basename:`Md5)
       | `Sequential ->
         (* 0-based indexing; last post numbered [n-1] *)
         let digits = List.length ids - 1 |> Int.to_string |> String.length in
         let pad = sprintf "%0*d" digits in
         List.mapi ids ~f:(fun i -> download ~basename:(`Basename (pad i))))
  ;;
end
