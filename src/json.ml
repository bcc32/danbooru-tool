open! Core
open! Async

include Or_error.Monad_infix

type t = Yojson.Basic.t

let rec sexp_of_t =
  function
  | `Assoc  a -> [%sexp_of: (string, t) List.Assoc.t] a
  | `Bool   b -> sexp_of_bool b
  | `Float  f -> sexp_of_float f
  | `Int    i -> sexp_of_int i
  | `List   l -> [%sexp_of: t list] l
  | `Null     -> Atom "null"
  | `String s -> Atom s
;;

let property t ~key =
  Yojson.Basic.Util.(
    match member key t with
    | `Null -> Or_error.error_s [%message "no such key" (t : t) (key : string)]
    | t     -> Ok t)
;;

let wrap f = fun t -> Or_error.try_with (fun () -> f t)

include struct
  open Yojson.Basic.Util
  let to_int    = wrap to_int
  let to_string = wrap to_string
  let to_list   = wrap to_list
end
