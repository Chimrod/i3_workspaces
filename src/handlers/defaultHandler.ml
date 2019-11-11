module type HANDLER = sig

  (** Function to call on workspace change *)
  val workspace_focus: Configuration.t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val workspace_init: Configuration.t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val window_create: Configuration.t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

  val window_close: Configuration.t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t
end


module M = struct
  let workspace_focus _ini ~workspace:_event _name state =
    state

  let workspace_init _ini ~workspace:_event _name state =
    state

  let window_create _ini ~workspace:_node ~container:_ state =
    state

  let window_close _ini ~workspace:_node ~container:_ state =
    state
end
