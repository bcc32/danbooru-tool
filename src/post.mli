open! Core
open! Async

type t [@@deriving sexp]

val of_json : Json.t -> t Or_error.t

val get
  :  int
  -> log  : Log.t
  -> http : Http.t
  -> t Deferred.Or_error.t

val download
  :  t
  -> log      : Log.t
  -> http     : Http.t
  -> basename : [ `Md5 | `Basename of string ]
  -> unit Deferred.Or_error.t
