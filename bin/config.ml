open! Core
open! Async
open Cmdliner

let output_dir =
  Arg.info [ "d"; "output-dir" ]
    ~docs:Manpage.s_common_options
    ~docv:"DIR"
    ~doc:"Save downloaded image files to directory $(docv)."
  |> Arg.(opt string ".")
  |> Arg.value
;;

let log_level =
  let of_list verbosity =
    match verbosity with
    | []  -> `Error
    | [_] -> `Info
    | _   -> `Debug
  in
  let flag_count =
    Arg.info [ "v"; "verbose" ]
      ~docs:Manpage.s_common_options
      ~doc:"Increase the level of verbosity."
    |> Arg.flag_all
    |> Arg.value
  in
  Term.(pure of_list $ flag_count)
;;

let auth =
  let auth_conv =
    let parse s =
      match Danbooru_lib.Auth.of_string s with
      | auth -> Ok auth
      | exception _ -> Error (`Msg "malformed auth string")
    in
    Arg.conv (parse, Danbooru_lib.Auth.pp)
  in
  Arg.info [ "auth" ]
    ~env:(Arg.env_var "DANBOORU_AUTH"
            ~doc:"User and API key used to access Danbooru API.")
    ~docs:Manpage.s_common_options
    ~docv:"USER:API_KEY"
    ~doc:"Set the user and API key used to access the Danbooru API."
  |> Arg.(opt (some auth_conv) None)
  |> Arg.value
;;

let max_concurrent_jobs =
  Arg.info [ "max-connections" ]
    ~docs:Manpage.s_common_options
    ~docv:"INT"
    ~doc:"Set the maximum number of simultaneous connections."
  |> Arg.(opt int 5)
  |> Arg.value
;;

let term =
  let make_config output_dir log_level auth max_concurrent_jobs =
    Danbooru_lib.Config.create
      ~output_dir
      ~log_level
      ~auth
      ~max_concurrent_jobs
  in
  Term.(pure make_config $ output_dir $ log_level $ auth $ max_concurrent_jobs)
;;
