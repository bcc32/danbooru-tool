open! Core
open! Async

type t =
  { output_dir   : string
  ; auth         : Auth.t option
  ; rate_limiter : Rate_limiter.t }
[@@deriving fields]

val download : t -> Uri.t -> filename:string -> unit Deferred.Or_error.t

val get_string : t -> Uri.t -> string Deferred.Or_error.t
val get_json   : t -> Uri.t -> Json.t Deferred.Or_error.t
