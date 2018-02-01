open! Core
open! Async

type t

val create : Http.t -> t

val download_posts
  :  t
  -> int list
  -> naming_scheme : [ `Md5 | `Sequential ]
  -> unit Deferred.Or_error.t
