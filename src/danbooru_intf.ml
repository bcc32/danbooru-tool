open! Core
open! Async

module type S = sig
  module Config : Config.S

  (* Version of Post for export *)
  module Post : sig
    type t

    val download
      :  t
      -> basename:[ `Md5 | `Basename of string ]
      -> unit Async.Deferred.Or_error.t
  end

  module Downloader : Downloader.S
  module Pool : Pool.S
  module Tags : Tags.S with module Post := Post
  module Tree : Tree.S
end

module type Danbooru = sig
  module type S = S

  module Make (Config : Config.S) : S with module Config = Config
end
