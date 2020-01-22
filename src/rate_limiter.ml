open! Core
open! Async

type t = unit Throttle.t

let create ~max_concurrent_jobs =
  Throttle.create ~max_concurrent_jobs ~continue_on_error:true
;;

let enqueue = Throttle.enqueue
