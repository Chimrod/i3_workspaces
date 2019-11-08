module type HANDLER = sig

  (** Function to call on workspace change 
    The function is called with the given parameters :
    - Configuration is the application config
    - Workspace
    - the workspace name
    - The pointer the I3 actions to execute
    *)
  val workspace_focus: Configuration.t -> I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  (** Function to call on workspace creation *)
  val workspace_init: Configuration.t -> I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

  (** Function to call on window creation.
    The given node is the window workspace *)
  val window_create: Configuration.t -> I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

  (** Function to call on window closing
    The given node is the focused workspace *)
  val window_close: Configuration.t -> I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t
end

module M:HANDLER
