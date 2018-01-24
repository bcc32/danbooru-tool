open! Core

val make_uri
  :  ?userinfo:string
  -> ?path:string
  -> ?query:(string * string list) list
  -> ?fragment:string
  -> unit
  -> Uri.t
