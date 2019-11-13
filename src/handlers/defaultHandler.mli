(** Default module to include in all handlers.

  The module provide default fonction which does nothing and can be overriden
  to declare specific effects

*)

val init: Configuration.t -> Configuration.t option

(** Function to call on workspace change 
  The function is called with the given parameters :
  - The result from the init function
  - Workspace
  - the workspace name
  - The pointer the I3 actions to execute
  *)
val workspace_focus: 'a -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

(** Function to call on workspace creation *)
val workspace_init: 'a -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t

(** Function to call on window creation.
  The given node is the window workspace *)
val window_create: 'a -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

(** Function to call on window closing
  The given node is the focused workspace *)
val window_close: 'a -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t

