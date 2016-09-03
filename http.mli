open Core.Std
open Async.Std

val get      : Uri.t -> string            Deferred.Or_error.t
val get_json : Uri.t -> Yojson.Basic.json Deferred.Or_error.t
