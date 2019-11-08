(** Register a new handler *)
val register_handler: (module DefaultHandler.HANDLER) -> unit

(** Mananeg an I3ipc workspace event *)
val workspace_event: I3ipc.connection -> I3ipc.Event.workspace_event_info -> Configuration.t -> Common.Actions.answer Lwt.t

(** Mananeg an I3ipc window event *)
val window_event: I3ipc.connection -> I3ipc.Event.window_event_info -> Configuration.t -> Common.Actions.answer Lwt.t

