open! Core
open! Async
include Post_intf

module Maybe_banned = struct
  type 'a t =
    | Banned
    | Not_banned of 'a
  [@@deriving sexp]
end

type unbanned =
  { id : int
  ; file_ext : string
  ; file_url : string
  ; md5 : string
  }
[@@deriving fields, sexp]

(** Might be absent if the post cannot be downloaded, e.g., it is a banned paid reward. *)
type t =
  { provided_id : int option
  ; maybe_banned : unbanned Maybe_banned.t
  ; json : Json.t
  }
[@@deriving sexp]

let of_json ?id:provided_id json =
  let unbanned =
    let%map.Or_error id = Json.(json |> property ~key:"id" >>= to_int)
    and md5 = Json.(json |> property ~key:"md5" >>= to_string)
    and file_url = Json.(json |> property ~key:"file_url" >>= to_string)
    and file_ext = Json.(json |> property ~key:"file_ext" >>= to_string) in
    { id; file_ext; file_url; md5 }
  in
  { provided_id
  ; maybe_banned =
      (match unbanned with
       | Error _ -> Banned
       | Ok unbanned -> Not_banned unbanned)
  ; json
  }
;;

module Make (Config : Config.S) = struct
  type nonrec t = t [@@deriving sexp]

  let of_json = of_json

  let get id =
    let json =
      let path = sprintf "/posts/%d.json" id in
      Config.Which_server.make_uri () ~path |> Http.get_json Config.http
    in
    let%map json =
      Deferred.Or_error.tag_arg json "Post.get" id (fun id ->
        [%message "error getting post data" ~post_id:(id : int)])
    in
    let t = Or_error.(json >>| of_json ~id) in
    if Or_error.is_ok t then Log.info Config.log "post %d data" id;
    t
  ;;

  let page_size = 100

  let search tags =
    let http = Config.http in
    let tags = String.concat tags ~sep:" " in
    let base_uri =
      Config.Which_server.make_uri
        ()
        ~path:"/posts.json"
        ~query:[ "tags", [ tags ]; "limit", [ Int.to_string page_size ] ]
    in
    Pipe.create_reader ~close_on_exception:false (fun writer ->
      let rec loop page =
        let uri = Uri.add_query_param' base_uri ("page", Int.to_string page) in
        match%bind
          Http.get_json http uri
          >>| Or_error.bind ~f:Json.to_list
          >>|? List.map ~f:of_json
        with
        | Error _ -> raise_s [%message "error"]
        | Ok posts ->
          (match posts with
           | [] -> return ()
           | _ :: _ as posts ->
             List.iter posts ~f:(Pipe.write_without_pushback writer);
             loop (page + 1))
      in
      loop 1)
  ;;

  let download t ~basename =
    match t.maybe_banned with
    | Banned ->
      return
        (Or_error.error_s
           [%message
             "Post missing download information"
               ~post_id:(t.provided_id : (int option[@sexp.option]))])
    | Not_banned { id; file_ext; file_url; md5 } ->
      let basename =
        match basename with
        | `Md5 -> md5
        | `Basename b -> b
      in
      let filename = basename ^ "." ^ file_ext in
      let uri = Config.Which_server.resolve (Uri.of_string file_url) in
      let%map result = Http.download Config.http uri ~filename in
      if Or_error.is_ok result then Log.info Config.log "%s %d" md5 id;
      Or_error.tag_s
        result
        ~tag:[%message "Couldn't download post" ~post_id:(id : int) (filename : string)]
  ;;
end
