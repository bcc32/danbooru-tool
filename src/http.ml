open! Core
open! Async

let get uri =
  let headers =
    Cohttp.Header.(
      let header = init () in
      let header =
        match !Auth.t with
        | Some { login; api_key } -> add_authorization header (`Basic (login, api_key))
        | None -> header
      in
      header)
  in
  let%bind response, body =
    Rate_limiter.(enqueue (t ()) (fun () -> Cohttp_async.Client.get ~headers uri))
  in
  if Cohttp.Code.(is_success (code_of_status response.status))
  then (Cohttp_async.Body.to_string body >>| Or_error.return)
  else begin
    Deferred.Or_error.error_s
      [%message
        "non-OK status code"
          ~status_code:(response.status : Cohttp.Code.status_code)
          ~uri:(Uri.to_string uri : string)
      ]
  end
;;

let json_of_string string = Or_error.try_with (fun () -> Yojson.Basic.from_string string)

let get_json uri =
  let%map body = get uri in
  Or_error.bind body ~f:json_of_string
;;

let download uri ~filename =
  let%bind contents = get uri in
  match contents with
  | Error _ as err -> return err
  | Ok c ->
    Writer.with_file filename ~f:(fun w ->
      Writer.write w c;
      Writer.close w >>| Or_error.return)
;;
