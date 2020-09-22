open! Core
open! Async

module type S = sig
  type t [@@deriving sexp]

  val get : int -> t Deferred.Or_error.t
  val save_all : t -> unit Deferred.Or_error.t
end

module type Tree = sig
  module type S = S

  module Make (Config : Config.S) (Downloader : Downloader.S) : S
end
