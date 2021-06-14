open! Core
open! Async

type t

val create : ?auth:Auth.t -> output_dir:string -> rate_limiter:Rate_limiter.t -> unit -> t
val download : t -> Uri.t -> filename:string -> unit Deferred.Or_error.t
val get_string : ?headers:Cohttp.Header.t -> t -> Uri.t -> string Deferred.Or_error.t
val get_json : ?headers:Cohttp.Header.t -> t -> Uri.t -> Json.t Deferred.Or_error.t
