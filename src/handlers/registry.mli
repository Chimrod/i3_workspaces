(** Register a new handler *)
module type HANDLER = sig

  type t

  val init: Configuration.t -> t option

  (** Function to call on workspace change *)
  val workspace_focus: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val workspace_init: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val window_create: t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

  val window_close: t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t
end

val add: Configuration.t -> (module HANDLER) -> unit

(** Mananeg an I3ipc workspace event *)
val workspace_event: I3ipc.connection -> I3ipc.Event.workspace_event_info -> Common.Actions.answer Lwt.t

(** Mananeg an I3ipc window event *)
val window_event: I3ipc.connection -> I3ipc.Event.window_event_info -> Common.Actions.answer Lwt.t

