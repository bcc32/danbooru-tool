open Core.Std
open Async.Std

type t

val get : int -> t Deferred.Or_error.t
val id        : t -> int
val md5       : t -> string
val file_url  : t -> string
val extension : t -> string
val save : t -> basename:string -> unit Deferred.Or_error.t
