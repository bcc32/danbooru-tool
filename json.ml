open! Core.Std
open! Async.Std

let property json ~name =
  let find_or_error mapping =
    match List.Assoc.find mapping name with
    | Some data -> Ok data
    | None -> Or_error.error_s [%message "no such property" (name : string)]
  in
  match json with
  | `Assoc mapping -> find_or_error mapping
  | `Bool _ | `Float _ | `Int _ | `List _ | `Null | `String _ ->
    let json = Yojson.Basic.to_string json in
    Or_error.error_s [%message "not a JSON object" (json : string)]
;;

let property_s json ~name =
  let open Or_error.Let_syntax in
  match%bind property json ~name with
  | `String s -> Ok s
  | `Assoc _ | `Bool _ | `Float _ | `Int _ | `List _ | `Null as value ->
    let value = Yojson.Basic.to_string value in
    Or_error.error_s [%message "not a string" (value : string)]
;;
