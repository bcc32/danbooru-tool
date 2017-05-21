open! Core
open! Async

val download : Uri.t -> filename:string -> unit Deferred.Or_error.t

(** the output directory for [download] *)
val output_dir : string ref

val get      : Uri.t -> string            Deferred.Or_error.t
val get_json : Uri.t -> Yojson.Basic.json Deferred.Or_error.t
