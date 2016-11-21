open! Core.Std
open! Async.Std

type t =
  { id : int
  ; post_ids : int list
  }
[@@deriving fields]
;;

let read_posts json =
  let post_ids = Or_error.try_with (fun () ->
    Yojson.Basic.Util.(
      json
      |> member "post_ids"
      |> to_string))
  in
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
  let%map post_ids =
    let%bind json = json in
    read_posts json
  in
  { id; post_ids }
;;
