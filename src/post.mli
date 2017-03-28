open! Core
open! Async

type t = private
  { id        : int
  ; file_ext  : string
  ; file_url  : string
  ; md5       : string
  }
[@@deriving fields, sexp]

val get : int -> t Deferred.Or_error.t
val download : t -> basename:[ `Md5 | `Basename of string ] -> unit Deferred.Or_error.t
