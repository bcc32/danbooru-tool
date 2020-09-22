open! Core
open! Async
open! Import

let%expect_test "download single post" =
  test (fun (module Testbooru) ->
    let open Testbooru in
    let%bind post = Post.get 1 >>| ok_exn in
    let%bind () = Post.download post ~basename:`Md5 >>| ok_exn in
    let%bind file_exists = Sys.file_exists_exn "f49cdde9bcd7edb54e597e8c21777dbb.png" in
    require [%here] file_exists;
    [%expect {| |}])
;;
