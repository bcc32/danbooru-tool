open! Core
open! Async

val download_posts
  :  int list
  -> max_connections:int
  -> naming_scheme:[ `Md5 | `Sequential ]
  -> unit Deferred.Or_error.t
