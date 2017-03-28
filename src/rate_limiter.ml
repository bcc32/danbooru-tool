open! Core
open! Async

type t = Limiter.Throttle.t

let create_exn n =
  Limiter.Throttle.create_exn
    ~concurrent_jobs_target:n
    ~continue_on_error:true
    ()
;;

let enqueue' t f data =
  Limiter.Throttle.enqueue' t f data
  >>| function
  | Aborted    -> Or_error.error_string "aborted"
  | Raised exn -> Or_error.of_exn exn
  | Ok result  -> result
;;

let enqueue t f data = enqueue' t (fun data -> f data >>| Or_error.return) data
