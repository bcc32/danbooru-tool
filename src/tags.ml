open! Core
open! Async
include Tags_intf

module Make (Config : Config.S) (Post : Post.S) = struct
  let page_size = 20

  let search tags =
    let http = Config.http in
    let tags = String.concat tags ~sep:" " in
    let%bind post_count =
      let uri =
        Which_server.make_uri () ~path:"/counts/posts.json" ~query:[ "tags", [ tags ] ]
      in
      let%map json = Http.get_json http uri in
      Json.(json >>= property ~key:"counts" >>= property ~key:"posts" >>= to_int)
    in
    match post_count with
    | Error _ as err -> return err
    | Ok post_count ->
      (* round up to full page *)
      let page_count = (post_count + page_size - 1) / page_size in
      let base_uri =
        Which_server.make_uri
          ()
          ~path:"/posts.json"
          ~query:[ "tags", [ tags ]; "limit", [ Int.to_string page_size ] ]
      in
      Deferred.Or_error.List.init ~how:`Parallel page_count ~f:(fun page ->
        let page = page + 1 in
        let uri = Uri.add_query_param' base_uri ("page", Int.to_string page) in
        Http.get_json http uri >>| Or_error.bind ~f:Json.to_list)
      >>|? List.concat
      >>|? List.map ~f:Post.of_json
  ;;
end
