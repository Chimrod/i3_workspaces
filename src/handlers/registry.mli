module type HANDLER = sig

  type t

  val init: Configuration.t -> t option

  (** Function to call on workspace change 
    The function is called with the given parameters :
    - The result from the init function
    - Workspace
    - the workspace name
    - The pointer the I3 actions to execute
    *)
  val workspace_focus: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t Lwt.t

  val workspace_init: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t Lwt.t

  val window_create: t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t Lwt.t

  val window_close: t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t Lwt.t
end

(** Register a new handler *)
val add: Configuration.t -> (module HANDLER) -> unit

(** Mananeg an I3ipc workspace event *)
val workspace_event: I3ipc.connection -> I3ipc.Event.workspace_event_info -> Common.Actions.answer Lwt.t

(** Mananeg an I3ipc window event *)
val window_event: I3ipc.connection -> I3ipc.Event.window_event_info -> Common.Actions.answer Lwt.t

