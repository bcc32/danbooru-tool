open! Core

(* TODO make this configurable *)
let scheme = "https"
let host   = "danbooru.donmai.us"

let make_uri = Uri.make ~scheme ~host ?port:None

let resolve =
  let base = Uri.make () ~scheme ~host in
  Uri.resolve scheme base
;;
