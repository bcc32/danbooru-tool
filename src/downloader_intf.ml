open! Core
open! Async

module type S = sig
  val download_posts
    :  int list
    -> naming_scheme:[ `Md5 | `Sequential ]
    -> unit Deferred.Or_error.t
end

module type Downloader = sig
  module type S = S

  module Make (Config : Config.S) (Post : Post.S) : S
end
