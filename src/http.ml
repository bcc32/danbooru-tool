open! Core
open! Async

type t =
  { auth : Auth.t option
  ; rate_limiter : Rate_limiter.t
  ; output_dir : string Deferred.t
  }

let create ?auth ~output_dir ~rate_limiter () =
  let output_dir =
    let%map () = Unix.mkdir ~p:() output_dir in
    output_dir
  in
  { auth; rate_limiter; output_dir }
;;

let get_body t uri ~f =
  let headers =
    Option.fold t.auth ~init:(Cohttp.Header.init ()) ~f:(fun header { login; api_key } ->
      Cohttp.Header.add_authorization header (`Basic (login, api_key)))
  in
  Rate_limiter.enqueue t.rate_limiter (fun () ->
    let open Deferred.Or_error.Let_syntax in
    let%bind response, body =
      (* [get] can raise, e.g., if there is no response; this should catch those
         exceptions and turn them into [Error]s *)
      Monitor.try_with_or_error (fun () -> Cohttp_async.Client.get uri ~headers)
    in
    if Cohttp.Code.(is_success (code_of_status response.status))
    then f body
    else
      Deferred.Or_error.error_s
        [%message
          "non-OK status code"
            ~status_code:(response.status : Cohttp.Code.status_code)
            ~uri:(Uri.to_string uri : string)])
;;

let get_string t uri =
  get_body t uri ~f:(fun body -> Cohttp_async.Body.to_string body |> Deferred.ok)
;;

let json_of_string string = Or_error.try_with (fun () -> Yojson.Basic.from_string string)

let get_json t uri =
  let%map body = get_string t uri in
  Or_error.(body >>= json_of_string)
;;

let get_pipe t uri ~f = get_body t uri ~f:(fun body -> f (Cohttp_async.Body.to_pipe body))

let download t uri ~filename =
  let%bind output_dir = t.output_dir in
  let path = Filename.concat output_dir filename in
  get_pipe t uri ~f:(fun body ->
    Writer.with_file_atomic path ~f:(fun w ->
      let w = Writer.pipe w in
      Pipe.transfer body w ~f:Fn.id)
    |> Deferred.ok)
;;
