open! Core
open! Async
include Or_error.Monad_infix

type value = Ezjsonm.value
type t = Ezjsonm.t

let of_string = Ezjsonm.from_string

let rec sexp_of_value : Ezjsonm.value -> Sexp.t = function
  | `O a -> [%sexp_of: (string, value) List.Assoc.t] a
  | `Bool b -> [%sexp_of: bool] b
  | `Float f -> [%sexp_of: float] f
  | `A l -> [%sexp_of: value list] l
  | `Null -> Atom "null"
  | `String s -> Atom s
;;

let sexp_of_t = (sexp_of_value :> t -> Sexp.t)

module Of_json = struct
  type nonrec 'a t = value -> 'a

  let run t json = Or_error.try_with (fun () -> t (json :> value))
  let int = Ezjsonm.get_int
  let string = Ezjsonm.get_string
  let list = Ezjsonm.get_list

  (* FIXME: Try to get better error messages here. *)
  let ( @. ) field t json = t (Ezjsonm.find json [ field ])
  let return a = Fn.const a
  let map t ~f json = f (t json)
  let bind t ~f json = f (t json) json

  include Monad.Make (struct
      type nonrec 'a t = 'a t

      let return = return
      let map = `Custom map
      let bind = bind
    end)

  module Let_syntax = struct
    include Let_syntax

    module Let_syntax = struct
      include Let_syntax

      module Open_on_rhs = struct
        let ( @. ) = ( @. )
        let int = int
        let string = string
        let list = list
      end
    end
  end
end
