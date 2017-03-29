open! Core
open! Async

type t

(* singleton *)
val t : unit -> t
val max_concurrent_jobs : int ref

val enqueue  : t -> (unit -> 'a Deferred.t)          -> 'a Deferred.Or_error.t
val enqueue' : t -> (unit -> 'a Deferred.Or_error.t) -> 'a Deferred.Or_error.t

val param : unit Command.Param.t
