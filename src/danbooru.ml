open! Core
open! Async
include Danbooru_intf

module Make (Config : Config.S) = struct
  module Config = Config
  module Post = Post.Make (Config)
  module Downloader = Downloader.Make (Config) (Post)
  module Pool = Pool.Make (Config) (Downloader)
  module Tree = Tree.Make (Config) (Downloader)
end
