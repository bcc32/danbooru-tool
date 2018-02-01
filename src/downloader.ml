open! Core
open! Async

type t =
  { log  : Log.t
  ; http : Http.t }

let create ~log ~http = { log; http }

let download { log; http } id ~basename =
  let open Deferred.Or_error.Let_syntax in
  let%bind post = Post.get id ~log ~http in
  Post.download post ~log ~http ~basename
;;

let download_posts t ids ~naming_scheme =
  Deferred.Or_error.all_ignore (
    match naming_scheme with
    | `Md5 -> List.map ids ~f:(download t ~basename:`Md5)
    | `Sequential ->
      (* 0-based indexing; last post numbered [n-1] *)
      let digits = List.length ids - 1 |> Int.to_string |> String.length in
      let pad = sprintf "%0*d" digits in
      List.mapi ids ~f:(fun i -> download t ~basename:(`Basename (pad i))))
;;
