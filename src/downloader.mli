open! Core
open! Async

type t

val create
  :  log  : Log.t
  -> http : Http.t
  -> t

val download_posts
  :  t
  -> int list
  -> naming_scheme : [ `Md5 | `Sequential ]
  -> unit Deferred.Or_error.t
