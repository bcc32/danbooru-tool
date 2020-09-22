open! Core
open! Async
include Or_error.Monad_infix

type t = Yojson.Basic.t

let sexp_of_t t = [%sexp_of: string] (Yojson.Basic.to_string t)
let t_of_sexp sexp = Yojson.Basic.from_string ([%of_sexp: string] sexp)

let property t ~key =
  Yojson.Basic.Util.(
    match member key t with
    | `Null -> Or_error.error_s [%message "no such key" (key : string) (t : t)]
    | t -> Ok t)
;;

let wrap f t = Or_error.try_with (fun () -> f t)

include struct
  open Yojson.Basic.Util

  let to_int = wrap to_int
  let to_string = wrap to_string
  let to_list = wrap to_list
end
