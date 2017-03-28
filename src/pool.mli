open! Core
open! Async

type t = private
  { id         : int
  ; post_count : int
  ; post_ids   : int list
  }
[@@deriving fields]

val get : int -> t Deferred.Or_error.t

val save_all
  :  t
  -> naming_scheme:[ `Md5 | `Sequential ]
  -> max_connections:int
  -> unit Deferred.Or_error.t
