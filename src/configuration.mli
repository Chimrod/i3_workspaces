type t

(** Load the configuration from the given file name *)
val load : string -> t option

(** Load the values from the section and given key *)
val load_values: t -> string -> string -> string list

val load_value: t -> string -> string -> string option
