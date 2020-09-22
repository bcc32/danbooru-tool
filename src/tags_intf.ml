open! Core
open! Async

module type S = sig
  module Post : sig
    type t
  end

  val search : string list -> Post.t list Deferred.Or_error.t
end

module type Tags = sig
  module type S = S

  module Make (Config : Config.S) (Post : Post.S) : S with module Post := Post
end
