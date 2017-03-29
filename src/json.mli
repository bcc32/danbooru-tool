open! Core
open! Async

type t = Yojson.Basic.json

val property : t -> key:string -> t Or_error.t

val to_int    : t -> int    Or_error.t
val to_string : t -> string Or_error.t
val to_list   : t -> t list Or_error.t

include module type of Or_error.Monad_infix
