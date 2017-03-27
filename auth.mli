open! Core
open! Async

type t =
  { login   : string
  ; api_key : string
  }
;;

val t : t option ref
val param : unit Command.Param.t
