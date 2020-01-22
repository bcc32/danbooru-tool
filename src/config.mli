open! Core
open! Async

type t = private
  { output_dir : string
  ; log : Log.t
  ; auth : Auth.t option
  ; rate_limiter : Rate_limiter.t
  ; http : Http.t
  ; downloader : Downloader.t
  }

val create
  :  output_dir:string
  -> log_level:Log.Level.t
  -> auth:Auth.t option
  -> max_concurrent_jobs:int
  -> t
