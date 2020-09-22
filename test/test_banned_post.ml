open! Core
open! Async
open! Import

let%expect_test "download banned post" =
  test (fun (module Testbooru) ->
    let open Testbooru in
    let%bind post = Post.get 36 >>| ok_exn in
    let%bind () =
      require_does_raise_async [%here] (fun () ->
        Post.download post ~basename:`Md5 >>| ok_exn)
    in
    [%expect {| ("Post missing download information" (post_id 36)) |}])
;;
