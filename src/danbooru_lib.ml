module Auth = Auth
module Config = Config
module Downloader = Downloader
module Pool = Pool
module Tags = Tags

(* Version of Post for export *)
module Post = struct
  type t = Post.t

  let download t ~config:({ log; http; _ } : Config.t) = Post.download t ~log ~http
end
