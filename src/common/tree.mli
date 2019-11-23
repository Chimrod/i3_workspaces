type t = I3ipc.Reply.node

val traverse: (t -> bool) -> t -> t option

val get_focused_workspace: t -> t option

val get_workspace: t -> t -> t option

val has_container: t -> bool

