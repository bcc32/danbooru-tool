open! Core
open! Async

(** Configuration options common to all commands. *)
val term : Danbooru_lib.Config.t Cmdliner.Term.t
