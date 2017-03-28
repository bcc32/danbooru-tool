open! Core
open! Async

type t = unit Throttle.t

let create_exn n =
  Throttle.create
    ~max_concurrent_jobs:n
    ~continue_on_error:true
;;

let enqueue' t f = Throttle.enqueue t f
;;

let enqueue t f = enqueue' t (fun () -> f () >>| Or_error.return)
