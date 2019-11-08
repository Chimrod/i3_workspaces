module type HANDLER = sig

  (** Function to call on workspace change *)
  val workspace_focus: Configuration.t -> I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val workspace_init: Configuration.t -> I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  val window_create: Configuration.t -> I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

  val window_close: Configuration.t -> I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t
end


module M = struct
  let workspace_focus _ini _event _name state =
    state

  let workspace_init _ini _event _name state =
    state

  let window_create _ini _node state =
    state

  let window_close _ini _node state =
    state
end
