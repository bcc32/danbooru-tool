open! Core
open! Async

type t =
  { http : Http.t }

let create http = { http }

let download { http } id ~basename =
  let open Deferred.Or_error.Let_syntax in
  let%bind post = Post.get id ~http in
  Post.download post ~http ~basename
;;

(* FIXME style *)
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
