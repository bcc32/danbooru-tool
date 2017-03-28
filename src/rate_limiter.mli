open! Core
open! Async

type t

val create_exn : int -> t

val enqueue  : t -> (unit -> 'a Deferred.t)          -> 'a Deferred.Or_error.t
val enqueue' : t -> (unit -> 'a Deferred.Or_error.t) -> 'a Deferred.Or_error.t
