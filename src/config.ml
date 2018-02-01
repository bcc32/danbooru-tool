open! Core
open! Async

type t =
  { output_dir   : string
  ; log          : Log.t
  ; auth         : Auth.t option
  ; rate_limiter : Rate_limiter.t
  ; http         : Http.t
  ; downloader   : Downloader.t }

let create ~output_dir ~log_level ~auth ~max_concurrent_jobs =
  let log =
    let output = [ Log.Output.stdout () ] in
    Log.create ~level:log_level ~output ~on_error:`Raise
  in
  let rate_limiter = Rate_limiter.create ~max_concurrent_jobs in
  let http         = Http.create () ~output_dir ?auth ~rate_limiter in
  let downloader   = Downloader.create ~log ~http in
  { output_dir
  ; log
  ; auth
  ; rate_limiter
  ; http
  ; downloader }
