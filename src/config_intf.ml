open! Core
open! Async

let default_which_server = "danbooru.donmai.us"

module type S = sig
  val output_dir : string
  val log : Log.t
  val auth : Auth.t option
  val rate_limiter : Rate_limiter.t
  val http : Http.t

  module Which_server : Which_server.S
end

module type Config = sig
  module type S = S

  val create
    :  ?which_server:string (** default = [default_which_server] *)
    -> output_dir:string
    -> log_level:Log.Level.t
    -> auth:Auth.t option
    -> max_concurrent_jobs:int
    -> unit
    -> (module S)
end
