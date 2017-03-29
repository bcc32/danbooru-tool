open! Core
open! Async

val download_posts
  :  int list
  -> naming_scheme:[ `Md5 | `Sequential ]
  -> unit Deferred.Or_error.t
