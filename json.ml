open! Core
open! Async
open! Yojson.Basic.Util

include Or_error.Monad_infix

type t = Yojson.Basic.json

let rec sexp_of_t : t -> Sexp.t =
  function
  | `Assoc alist -> List.map alist ~f:(fun (k, v) -> [%sexp ((k : string), (v : t))]) |> List
  | `Bool b -> [%sexp_of: bool] b
  | `Float f -> [%sexp_of: float] f
  | `Int i -> [%sexp_of: int] i
  | `List ts -> List.map ts ~f:[%sexp_of: t] |> List
  | `Null -> Atom "null"
  | `String s -> Atom s
;;

let property t ~key =
  match member key t with
  | `Null -> Or_error.error_s [%message "no such key" (t : t) (key : string)]
  | t -> Ok t
;;

let wrap f = fun t -> Or_error.try_with (fun () -> f t)

let to_int    = wrap to_int
let to_string = wrap to_string
