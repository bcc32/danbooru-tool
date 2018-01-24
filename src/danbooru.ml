open! Core

(* TODO make this configurable *)
let scheme = "https"
let host = "danbooru.donmai.us"

let make_uri = Uri.make ~scheme ~host ?port:None
