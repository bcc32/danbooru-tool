open! Core
open! Async

(** Configuration options common to all commands. *)
val term : (module Danbooru_lib.Danbooru.S) Cmdliner.Term.t
