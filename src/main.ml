open! Core
open! Async
open Danbooru_tool

let output_dir =
  Command.Param.(
    flag "-output-dir" (optional_with_default "." string)
      ~doc:"dir output directory for downloaded posts, default cwd"
      ~aliases:[ "-d" ]
    |> map ~f:(fun d ->
      Core.Unix.mkdir_p d;
      Http.output_dir := d
    )
  )

let verbose =
  let set_level is_verbose =
    let level = if is_verbose then `Info else `Error in
    Log.Global.set_level level
  in
  Command.Param.(
    flag "-verbose" no_arg
      ~doc:" increase log output"
      ~aliases:[ "-v" ]
    |> map ~f:set_level
  )
;;

let global_flags =
  Command.Param.all_ignore
    [ Auth.param
    ; Rate_limiter.param
    ; output_dir
    ; verbose
    ]
;;

let command_with_global_flags param =
  let param = Command.Param.(global_flags *> param) in
  Command.async_or_error param
;;

let pool_command =
  let param =
    let open Command.Let_syntax in
    let%map_open pool_id = anon ("id" %: int)
    and md5 =
      flag "-md5" no_arg
        ~doc:" save to filename with MD5 hash (default is post index)"
    in
    fun () ->
      let open Deferred.Or_error.Let_syntax in
      let%bind pool = Pool.get pool_id in
      Pool.save_all pool ~naming_scheme:(if md5 then `Md5 else `Sequential)
  in
  command_with_global_flags param ~summary:"download a pool of Danbooru posts"
;;

let post_command =
  let param =
    let open Command.Let_syntax in
    let%map_open ids = anon ("id" %: int |> non_empty_sequence_as_list) in
    fun () ->
      Downloader.download_posts ids ~naming_scheme:`Md5
  in
  command_with_global_flags param ~summary:"download Danbooru posts by ID"
;;

let tags_command =
  let param =
    let open Command.Let_syntax in
    let%map_open tags = anon ("tag" %: string |> sequence) in
    fun () ->
      (* allow user to enter mutliple tags in single arg with spaces *)
      let tags = List.concat_map tags ~f:(String.split ~on:' ') in
      let open Deferred.Or_error.Let_syntax in
      let%bind posts = Post.search ~tags in
      List.map posts ~f:(Post.download ~basename:`Md5)
      |> Deferred.Or_error.all_ignore
  in
  command_with_global_flags param ~summary:"download Danbooru posts by tag"
;;

let command =
  Command.group ~summary:"Danbooru download tool"
    [ "pool", pool_command
    ; "post", post_command
    ; "tags", tags_command
    ]
;;

let build_info = "danbooru-tool"
let version    = "0.1.2"

let () = Command.run command ~build_info ~version
