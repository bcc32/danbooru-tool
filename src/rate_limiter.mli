open! Core
open! Async

type t

val create : max_concurrent_jobs:int -> t
val enqueue : t -> (unit -> 'a Deferred.t) -> 'a Deferred.t
