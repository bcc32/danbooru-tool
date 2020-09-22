open! Core
open! Async

module type S = sig
  val output_dir : string
  val log : Log.t
  val auth : Auth.t option
  val rate_limiter : Rate_limiter.t
  val http : Http.t
end

module type Config = sig
  module type S = S

  val create
    :  output_dir:string
    -> log_level:Log.Level.t
    -> auth:Auth.t option
    -> max_concurrent_jobs:int
    -> (module S)
end
