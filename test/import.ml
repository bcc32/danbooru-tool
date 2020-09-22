open! Core
open! Async
include Expect_test_helpers

let test (type a) (f : (module Danbooru_lib.Danbooru.S) -> a Deferred.t) : a Deferred.t =
  within_temp_dir (fun () ->
    let module Config =
      (val Danbooru_lib.Config.create
             ~which_server:"testbooru.donmai.us"
             ~output_dir:"."
             ~log_level:`Error
             ~auth:None
             ~max_concurrent_jobs:16
             ())
    in
    let module Testbooru = Danbooru_lib.Danbooru.Make (Config) in
    f (module Testbooru))
;;
