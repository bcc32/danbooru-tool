open Core.Std
open Async.Std

type t = private
  { id        : int
  ; file_url  : string
  ; md5       : string
  ; extension : string
  }
[@@deriving fields]
;;

val get : int -> t Deferred.Or_error.t
val save : t -> basename:string -> unit Deferred.Or_error.t
