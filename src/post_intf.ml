open! Core
open! Async

module type M = sig
  type t [@@deriving sexp]

  val of_json : ?id:int -> Json.t -> t
end

module type S = sig
  type t [@@deriving sexp]

  val of_json : ?id:int -> Json.t -> t
  val get : int -> t Deferred.Or_error.t
  val download : t -> basename:[ `Md5 | `Basename of string ] -> unit Deferred.Or_error.t
end

module type Post = sig
  module type S = S

  include M
  module Make (Config : Config.S) : S with type t = t
end
