open! Core
open! Async

type t

(* singleton *)
val t : unit -> t
val max_concurrent_jobs : int ref

val enqueue : t -> (unit -> 'a Deferred.t) -> 'a Deferred.t

val param : unit Command.Param.t
