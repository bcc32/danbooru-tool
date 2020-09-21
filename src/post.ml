open! Core
open! Async

(* TODO: Functorize these modules over http, log dependencies. *)

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
  }
;;

let get id ~log ~http =
  let json =
    let path = sprintf "/posts/%d.json" id in
    Danbooru.make_uri () ~path |> Http.get_json http
  in
  let%map json =
    Deferred.Or_error.tag_arg json "Post.get" id (fun id ->
      [%message "error getting post data" ~post_id:(id : int)])
  in
  let t = Or_error.(json >>| of_json ~id) in
  if Or_error.is_ok t then Log.info log "post %d data" id;
  t
;;

let download t ~log ~http ~basename =
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
    let uri = Danbooru.resolve (Uri.of_string file_url) in
    let%map result = Http.download http uri ~filename in
    if Or_error.is_ok result then Log.info log "%s %d" md5 id;
    Or_error.tag_s
      result
      ~tag:[%message "Couldn't download post" ~post_id:(id : int) (filename : string)]
;;
