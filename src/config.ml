open! Core
open! Async
include Config_intf

let create
      ?(which_server = default_which_server)
      ~output_dir
      ~log_level
      ~auth
      ~max_concurrent_jobs
      ()
  =
  let log =
    let output = [ Log.Output.stdout () ] in
    Log.create ~level:log_level ~output ~on_error:`Raise ()
  in
  let rate_limiter = Rate_limiter.create ~max_concurrent_jobs in
  let http = Http.create () ~output_dir ?auth ~rate_limiter in
  (module struct
    let output_dir = output_dir
    let log = log
    let auth = auth
    let rate_limiter = rate_limiter
    let http = http

    module Which_server = Which_server.Make (struct
        let scheme = "https"
        let host = which_server
      end)
  end : S)
;;
