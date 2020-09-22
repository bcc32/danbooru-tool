open! Core
include Which_server_intf

module Make (Server : Server) = struct
  open Server

  let make_uri = Uri.make ~scheme ~host ?port:None

  let resolve =
    let base = Uri.make () ~scheme ~host in
    Uri.resolve scheme base
  ;;
end
