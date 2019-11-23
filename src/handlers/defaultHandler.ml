let init conf = Some conf

let workspace_focus _ ~workspace:_event _name state =
  Lwt.return state

let workspace_init _ ~workspace:_event _name state =
  Lwt.return state

let window_create _ ~workspace:_node ~container:_ state =
  Lwt.return state

let window_close _ _ ~workspace:_node ~container:_ state =
  Lwt.return state
