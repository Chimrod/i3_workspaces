let init conf = Some conf

let workspace_focus _ ~workspace:_event _name state =
  state

let workspace_init _ ~workspace:_event _name state =
  state

let window_create _ ~workspace:_node ~container:_ state =
  state

let window_close _ ~workspace:_node ~container:_ state =
  state
