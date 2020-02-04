open! Core
open! Async

type value = Ezjsonm.value [@@deriving sexp_of]
type t = Ezjsonm.t [@@deriving sexp_of]

val of_string : string -> t

module Of_json : sig
  (** Simple reader monad for {!Json.t}. *)
  type nonrec 'a t

  val run : 'a t -> [< value ] -> 'a Or_error.t

  (** Read a specific field. *)
  val ( @. ) : string -> 'a t -> 'a t

  val int : int t
  val string : string t
  val list : 'a t -> 'a list t

  include Monad.S_without_syntax with type 'a t := 'a t

  module Let_syntax : sig
    val return : 'a -> 'a t

    include Monad.Infix with type 'a t := 'a t

    module Let_syntax : sig
      val return : 'a -> 'a t
      val bind : 'a t -> f:('a -> 'b t) -> 'b t
      val map : 'a t -> f:('a -> 'b) -> 'b t
      val both : 'a t -> 'b t -> ('a * 'b) t

      module Open_on_rhs : sig
        val ( @. ) : string -> 'a t -> 'a t
        val int : int t
        val string : string t
        val list : 'a t -> 'a list t
      end
    end
  end
end
