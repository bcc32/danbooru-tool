open! Core
open! Async

type t = unit Throttle.t

let create_exn n =
  Throttle.create
    ~max_concurrent_jobs:n
    ~continue_on_error:true
;;

let max_concurrent_jobs = ref 5

let param =
  let set_max_concurrent_jobs n = max_concurrent_jobs := n in
  Command.Param.(
    flag "-max-connections" (optional_with_default 5 int)
      ~doc:"int maximum number of simultaneous connections (default 5)"
    |> map ~f:set_max_concurrent_jobs
  )
;;

let t =
  let t = lazy (create_exn !max_concurrent_jobs) in
  fun () -> force t
;;

let enqueue = Throttle.enqueue
