open! Core
open! Async

type t =
  { id         : int
  ; post_count : int
  ; post_ids   : int list
  }
[@@deriving fields]
;;

let read_posts json =
  let post_ids = Json.(json |> property ~key:"post_ids" >>= to_string) in
  Or_error.(
    post_ids
    >>| String.split ~on:' '
    >>| List.map ~f:Int.of_string)
;;

let get id =
  let json =
    "http://danbooru.donmai.us/pools/" ^ Int.to_string id ^ ".json"
    |> Uri.of_string
    |> Http.get_json
  in
  let%map json = json in
  let open Or_error.Let_syntax in
  let%bind json = json in
  let%map post_ids = read_posts json
  and post_count = Json.(json |> property ~key:"post_count" >>= to_int) in
  { id; post_count; post_ids }
;;

let save_all ?(basename=`Numerical) ~max_connections t =
  let num_digits = t |> post_count |> Int.to_string |> String.length in
  let to_string n =
    let n = Int.to_string n in
    let len = num_digits - String.length n in
    if len > 0
    then (String.make len '0' ^ n)
    else (n)
  in
  let throttle = Rate_limiter.create_exn max_connections in
  let get_post id =
    let%map result = Rate_limiter.enqueue' throttle Post.get id in
    Or_error.tag_arg result "get_post" ()
      (fun () -> [%message "" ~post_id:(id : int) ~pool_id:(t.id : int)])
  in
  let save_post n post =
    let basename =
      match basename with
      | `Md5       -> `Md5
      | `Numerical -> `Basename (to_string n)
    in
    let%map result = Rate_limiter.enqueue' throttle (Post.download ~basename) post in
    Or_error.tag_arg result "save_post" ()
      (fun () -> [%message "" ~post_id:(post.id : int) ~pool_id:(t.id : int)])
  in
  List.mapi t.post_ids ~f:(fun n id -> Deferred.Or_error.(id |> get_post >>= save_post n))
  |> Deferred.Or_error.all_ignore
;;
