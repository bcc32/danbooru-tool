open! Core
open! Async
include Config_intf

let create ~output_dir ~log_level ~auth ~max_concurrent_jobs =
  let log =
    let output = [ Log.Output.stdout () ] in
    Log.create ~level:log_level ~output ~on_error:`Raise
  in
  let rate_limiter = Rate_limiter.create ~max_concurrent_jobs in
  let http = Http.create () ~output_dir ?auth ~rate_limiter in
  (module struct
    let output_dir = output_dir
    let log = log
    let auth = auth
    let rate_limiter = rate_limiter
    let http = http
  end : S)
;;
