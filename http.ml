open Core.Std
open Async.Std

let string_of_body body =
  match body with
  | `Empty     -> return ""
  | `String s  -> return s
  | `Strings s -> return (String.concat s)
  | `Pipe p    ->
    let%map strings = p |> Pipe.read_all >>| Queue.to_list in
    String.concat strings
;;

let get uri =
  let%bind response, body = Cohttp_async.Client.get uri in
  match response.status with
  | `OK -> (string_of_body body) >>| Result.return
  | _   ->
    Deferred.Or_error.error
      "non-OK status code"
      response.status
      [%sexp_of: Cohttp.Code.status_code]
;;

let json_of_string string =
  Or_error.try_with (fun () -> Yojson.Basic.from_string string)

let get_json uri =
  let%map body = get uri in
  Or_error.bind body json_of_string
;;
