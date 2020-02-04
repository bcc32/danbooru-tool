open! Core
open! Async

type t [@@deriving sexp]

val of_json : t Json.Of_json.t
val get : int -> log:Log.t -> http:Http.t -> t Deferred.Or_error.t

val download
  :  t
  -> log:Log.t
  -> http:Http.t
  -> basename:[ `Md5 | `Basename of string ]
  -> unit Deferred.Or_error.t
