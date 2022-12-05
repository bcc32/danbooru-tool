open! Core
open! Async
open Cmdliner

let which_server =
  Arg.info
    [ "h"; "host" ]
    ~docs:Manpage.s_common_options
    ~docv:"HOST"
    ~doc:"Connect to $(docv).  Default is Danbooru."
  |> Arg.(opt (some string) None)
  |> Arg.value
;;

let output_dir =
  Arg.info
    [ "d"; "output-dir" ]
    ~docs:Manpage.s_common_options
    ~docv:"DIR"
    ~doc:"Save downloaded image files to directory $(docv)."
  |> Arg.(opt string ".")
  |> Arg.value
;;

let log_level =
  let of_list verbosity =
    match verbosity with
    | [] -> `Error
    | [ _ ] -> `Info
    | _ -> `Debug
  in
  let flag_count =
    Arg.info
      [ "v"; "verbose" ]
      ~docs:Manpage.s_common_options
      ~doc:"Increase the level of verbosity."
    |> Arg.flag_all
    |> Arg.value
  in
  Term.(const of_list $ flag_count)
;;

let auth =
  let auth_conv =
    let parse s =
      match Danbooru_lib.Auth.of_string s with
      | auth -> Ok auth
      | exception exn ->
        Error
          (`Msg
             (Error.create_s [%message "malformed auth string" ~_:(exn : exn)]
              |> Error.to_string_hum))
    in
    Arg.conv (parse, Danbooru_lib.Auth.pp)
  in
  Arg.info
    [ "auth" ]
    ~env:
      (Cmd.Env.info "DANBOORU_AUTH" ~doc:"User and API key used to access Danbooru API.")
    ~docs:Manpage.s_common_options
    ~docv:"USER:API_KEY"
    ~doc:"Set the user and API key used to access the Danbooru API."
  |> Arg.(opt (some auth_conv) None)
  |> Arg.value
;;

let max_concurrent_jobs =
  Arg.info
    [ "max-connections" ]
    ~docs:Manpage.s_common_options
    ~docv:"INT"
    ~doc:"Set the maximum number of simultaneous connections."
  |> Arg.(opt int 5)
  |> Arg.value
;;

let term =
  let make_config which_server output_dir log_level auth max_concurrent_jobs =
    let (module Config) =
      Danbooru_lib.Config.create
        ?which_server
        ~output_dir
        ~log_level
        ~auth
        ~max_concurrent_jobs
        ()
    in
    (module Danbooru_lib.Danbooru.Make (Config) : Danbooru_lib.Danbooru.S)
  in
  Term.(
    const make_config $ which_server $ output_dir $ log_level $ auth $ max_concurrent_jobs)
;;
