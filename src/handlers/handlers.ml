module type HANDLER = sig

  val workspace_focus: Configuration.t -> I3ipc.Reply.node -> string -> Actions.t -> Actions.t

  val workspace_init: Configuration.t -> I3ipc.Reply.node -> string -> Actions.t -> Actions.t

  val window_create: Configuration.t -> I3ipc.Reply.node -> Actions.t -> Actions.t

  val window_close: Configuration.t -> I3ipc.Reply.node -> Actions.t -> Actions.t
end


let modules = ref []

let register_handler (m : (module HANDLER)) = begin
  modules := m :: (!modules)
end
let () = register_handler (module BinaryLayoutHandler)
let () = register_handler (module LoggerHandler)
let () = register_handler (module ExecHandler)

let get_handlers () = ! modules

let workspace_event conn {I3ipc.Event.change; I3ipc.Event.current; _} ini = begin

  let call_workspace_focus workspace name state (module H:HANDLER) = begin
    H.workspace_focus ini workspace name state
  end

  and call_workspace_init workspace name state (module H:HANDLER) = begin
    H.workspace_init ini workspace name state
  end

  in

  begin match current with
  | None -> Lwt.return Actions.empty
  | Some workspace ->
    begin match workspace.I3ipc.Reply.name with
    | None -> Lwt.return Actions.empty
    | Some name ->
      begin match change with
      | Focus ->
           get_handlers ()
        |> List.fold_left (call_workspace_focus workspace name) Actions.create
        |> Actions.apply conn
      | Init ->
           get_handlers ()
        |> List.fold_left (call_workspace_init workspace name) Actions.create
        |> Actions.apply conn
      | _ -> Lwt.return Actions.empty
      end
    end
  end
end

let window_event conn {I3ipc.Event.change; I3ipc.Event.container} ini = begin

  let%lwt tree = I3ipc.get_tree conn in

  let call_window_close workspace state (module H:HANDLER) = begin
    H.window_close ini workspace state
  end

  and call_window_create workspace state (module H:HANDLER) = begin
    H.window_create ini workspace state
  end in

  begin match change with
  | I3ipc.Event.Close ->
    let current_workspace = Common.Tree.get_focused_workspace tree in
    begin match current_workspace with
    | None -> Lwt.return Actions.empty
    | Some workspace ->
         get_handlers ()
      |> List.fold_left (call_window_close workspace) Actions.create
      |> Actions.apply conn
    end
  | I3ipc.Event.New ->
    let focused_workspace = Common.Tree.get_workspace tree container in
    begin match focused_workspace with
    | None -> Lwt.return Actions.empty
    | Some workspace ->
         get_handlers ()
      |> List.fold_left (call_window_create workspace) Actions.create
      |> Actions.apply conn
    end
  | I3ipc.Event.Move ->
    (* Move is like a Close event followed by a New one *)
    let current_workspace = Common.Tree.get_focused_workspace tree in
    let focused_workspace = Common.Tree.get_workspace tree container in
    let state = begin match current_workspace with
    | None -> Actions.create
    | Some workspace ->
         get_handlers ()
      |> List.fold_left (call_window_close workspace) Actions.create
    end in
    let state' = begin match focused_workspace with
    | None -> state
    | Some workspace ->
         get_handlers ()
      |> List.fold_left (call_window_create workspace) Actions.create
    end in
    Actions.apply conn state'
  | _ ->  Lwt.return Actions.empty
  end

end
