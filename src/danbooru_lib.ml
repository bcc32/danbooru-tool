(* TODO reduce the surface area of this library *)
module Auth       = Auth
module Config     = Config
module Danbooru   = Danbooru
module Downloader = Downloader
module Http       = Http
module Pool       = Pool
module Tags       = Tags

(* Version of Post for export *)
module Post = struct
  type t = Post.t

  let download t ~config = Post.download t ~http:(Config.http config)
end
