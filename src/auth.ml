open! Core
open! Async

type t =
  { login   : string
  ; api_key : string }
[@@deriving fields, sexp]

let pp fmt t = Sexp.pp_hum fmt [%sexp (t : t)]

let of_string s =
  let (login, api_key) = String.lsplit2_exn s ~on:':' in
  { login; api_key }
;;

let to_string { login; api_key } = sprintf "%s:%s" login api_key
