module Auth       = Auth
module Config     = Config
module Downloader = Downloader
module Pool       = Pool
module Tags       = Tags

(* Version of Post for export *)
module Post : sig
  type t = Post.t

  val download
    :  t
    -> config : Config.t
    -> basename : [ `Md5 | `Basename of string ]
    -> unit Async.Deferred.Or_error.t
end
