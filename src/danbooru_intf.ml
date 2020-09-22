open! Core
open! Async

module type S = sig
  module Config : Config.S
  module Downloader : Downloader.S
  module Pool : Pool.S
  module Post : Post.S
  module Tree : Tree.S
end

module type Danbooru = sig
  module type S = S

  module Make (Config : Config.S) : S with module Config = Config
end
