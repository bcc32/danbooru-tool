open! Core
open! Async

type t =
  { login : string
  ; api_key : string
  }
[@@deriving fields, sexp]

val pp : Format.formatter -> t -> unit
val of_string : string -> t
val to_string : t -> string
