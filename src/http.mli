open! Core
open! Async

type t =
  { auth         : Auth.t option
  ; rate_limiter : Rate_limiter.t
  }
[@@deriving fields]

val download : t -> Uri.t -> filename:string -> unit Deferred.Or_error.t

(** the output directory for [download] *)
val output_dir : string ref

val get      : t -> Uri.t -> string            Deferred.Or_error.t
val get_json : t -> Uri.t -> Yojson.Basic.json Deferred.Or_error.t
