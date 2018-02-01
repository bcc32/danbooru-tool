open! Core
open! Async

type t = private
  { id        : int
  ; file_ext  : string
  ; file_url  : string
  ; md5       : string
  }
[@@deriving sexp]

val of_json : Json.t -> t Or_error.t

val get
  :  int
  -> http : Http.t
  -> t Deferred.Or_error.t

val download
  :  t
  -> http     : Http.t
  -> basename : [ `Md5 | `Basename of string ]
  -> unit Deferred.Or_error.t
