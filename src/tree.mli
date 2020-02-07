open! Core
open! Async

type t [@@deriving sexp]

val get : int -> config:Config.t -> t Deferred.Or_error.t
val save_all : t -> config:Config.t -> unit Deferred.Or_error.t
