open! Core
open! Async

type t =
  { output_dir   : string
  ; auth         : Auth.t option
  ; rate_limiter : Rate_limiter.t }
[@@deriving fields]

let make_headers t =
  Option.fold t.auth ~init:(Cohttp.Header.init ())
    ~f:(fun header { login; api_key } ->
      Cohttp.Header.add_authorization header (`Basic (login, api_key)))
;;

let get_body t uri =
  let headers = make_headers t in
  let%bind (response, body) =
    Rate_limiter.enqueue t.rate_limiter
      (fun () -> Cohttp_async.Client.get uri ~headers)
  in
  if Cohttp.Code.(is_success (code_of_status response.status))
  then Deferred.(ok (return body))
  else (
    Deferred.Or_error.error_s
      [%message
        "non-OK status code"
          ~status_code:(response.status : Cohttp.Code.status_code)
          ~uri:(Uri.to_string uri : string)])
;;

let get_string t uri =
  let open Deferred.Or_error.Let_syntax in
  let%bind body = get_body t uri in
  Cohttp_async.Body.to_string body
  |> Deferred.ok
;;

let json_of_string string =
  Or_error.try_with (fun () -> Yojson.Basic.from_string string)
;;

let get_json t uri =
  let%map body = get_string t uri in
  Or_error.bind body ~f:json_of_string
;;

let get_pipe t uri =
  let open Deferred.Or_error.Let_syntax in
  let%map body = get_body t uri in
  Cohttp_async.Body.to_pipe body
;;

let download t uri ~filename =
  let path = Filename.concat t.output_dir filename in
  let open Deferred.Or_error.Let_syntax in
  let%bind contents = get_pipe t uri in
  Writer.with_file path ~f:(fun w ->
    let w = Writer.pipe w in
    Pipe.transfer contents w ~f:Fn.id)
  |> Deferred.ok
;;
