type t

val create: t

type answer

(** Create a container which swallow the given class *)
val swallow : string -> t -> t

(** Launch an application with i3 exec command *)
val launch : [`NoStartupId | `StartupId ] -> t -> string -> t

val split: I3ipc.Reply.node -> I3ipc.Reply.node_layout ->  t -> t

val layout: I3ipc.Reply.node -> I3ipc.Reply.node_layout ->  t -> t

val exec: focus:I3ipc.Reply.node -> string ->  t -> t

val empty: answer

(** Execute all the commands *)
val apply: I3ipc.connection -> t -> answer Lwt.t
