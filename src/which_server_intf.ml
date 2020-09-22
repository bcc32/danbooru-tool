open! Core

module type Server = sig
  val scheme : string
  val host : string
end

module type S = sig
  val make_uri
    :  ?userinfo:string
    -> ?path:string
    -> ?query:(string * string list) list
    -> ?fragment:string
    -> unit
    -> Uri.t

  val resolve : Uri.t -> Uri.t
end

module type Which_server = sig
  module type Server = Server
  module type S = S

  module Make (Server : Server) : S
end
