open! Core
open! Async

val search : config:Config.t -> string list -> Post.t list Deferred.Or_error.t
