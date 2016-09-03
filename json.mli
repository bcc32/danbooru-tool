open! Core.Std
open! Async.Std

val property   : Yojson.Basic.json -> name:string -> Yojson.Basic.json Or_error.t
val property_s : Yojson.Basic.json -> name:string -> string            Or_error.t
