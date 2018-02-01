open! Core
open! Async

let page_size = 20

let search ~config tags =
  let http = Config.http config in
  let tags = String.concat tags ~sep:" " in
  let%bind post_count =
    let uri =
      Danbooru.make_uri ()
        ~path:"/counts/posts.json"
        ~query:[ ("tags", [ tags ]) ]
    in
    let%map json = Http.get_json http uri in
    Json.(json >>= property ~key:"counts" >>= property ~key:"posts" >>= to_int)
  in
  match post_count with
  | Error _ as err -> return err
  | Ok post_count ->
    let page_count = Int.round_up post_count ~to_multiple_of:page_size / page_size in
    let base_uri =
      Danbooru.make_uri ()
        ~path:"/posts.json"
        ~query:[ ("tags", [ tags ]); ("limit", [ Int.to_string page_size ]) ]
    in
    List.range 1 page_count ~stop:`inclusive
    |> List.map ~f:(fun page ->
      let uri = Uri.add_query_param' base_uri ("page", Int.to_string page) in
      let%map json = Http.get_json http uri in
      let open Or_error.Let_syntax in
      let%bind posts = json >>= Json.to_list in
      List.map posts ~f:Post.of_json
      |> Or_error.all
    )
    |> Deferred.Or_error.all
    |> Deferred.Or_error.map ~f:List.concat
;;
