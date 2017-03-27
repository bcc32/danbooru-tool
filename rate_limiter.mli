open! Core
open! Async

type t

val create_exn : int -> t

val enqueue  : t -> ('a -> 'b Deferred.t)          -> 'a -> 'b Deferred.Or_error.t
val enqueue' : t -> ('a -> 'b Deferred.Or_error.t) -> 'a -> 'b Deferred.Or_error.t
