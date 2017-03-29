open! Core
open! Async

type t =
  { login   : string
  ; api_key : string
  }
;;

let t = ref None

let set_t (login, api_key) =
  t := Some { login; api_key }

let login_flag   = Command.Param.(flag "-login"   (optional string) ~doc:"string Danbooru username")
let api_key_flag = Command.Param.(flag "-api-key" (optional string) ~doc:"string Danbooru API key")

let param =
  Command.Param.(
    both login_flag api_key_flag
    |> map ~f:(fun (login, api_key) ->
      Option.both login api_key
      |> Option.iter ~f:set_t
    ))
;;

let () =
  Sys.getenv "DANBOORU_AUTH"
  |> Option.bind ~f:(String.lsplit2 ~on:':')
  |> Option.iter ~f:set_t
;;
