open Core.Std
open Async.Std

type t = private
  { id : int
  ; post_ids : int list
  }
[@@deriving fields]
;;

val get : int -> t Deferred.Or_error.t
