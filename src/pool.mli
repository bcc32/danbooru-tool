open! Core
open! Async

type t = private
  { id         : int
  ; post_count : int
  ; post_ids   : int list
  }
[@@deriving fields]

val get
  :  int
  -> config : Config.t
  -> t Deferred.Or_error.t

val save_all
  :  t
  -> config        : Config.t
  -> naming_scheme : [ `Md5 | `Sequential ]
  -> unit Deferred.Or_error.t
