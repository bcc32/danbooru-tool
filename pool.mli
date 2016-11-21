open Core.Std
open Async.Std

type t = private
  { id         : int
  ; post_count : int
  ; post_ids   : int list
  }
[@@deriving fields]
;;

val get : int -> t Deferred.Or_error.t
(* default is `Numerical *)
val save_all : ?basename:[ `Md5 | `Numerical ] -> t -> unit Deferred.Or_error.t
