open Core.Std
open Async.Std

type t = private
  { id        : int
  ; file_url  : string
  ; md5       : string
  ; extension : string
  }
[@@deriving fields, sexp]
;;

val get : int -> t Deferred.Or_error.t
val download : t -> basename:[ `Md5 | `Basename of string ] -> unit Deferred.Or_error.t
