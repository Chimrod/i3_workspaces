let (|>>=?) opt f = Option.bind ~f opt

let log_change out = begin function
  | I3ipc.Event.Init -> Printf.fprintf out "Init"
  | I3ipc.Event.Focus -> Printf.fprintf out "Focus"
  | I3ipc.Event.Empty -> Printf.fprintf out "Empty"
  | I3ipc.Event.Urgent -> Printf.fprintf out "Urgent"
end

let log_wks_name out = begin function
  | None -> ()
  | Some wks -> begin match wks.I3ipc.Reply.name with
    | Some name -> Printf.fprintf out "%s" name
    | None -> Printf.fprintf out "?"
    end
end

let workspace_event conn {I3ipc.Event.change; I3ipc.Event.current; _} ini : Actions.answer Lwt.t = begin

  let current_name_opt: string option = current
  |>>=? fun workspace -> workspace.I3ipc.Reply.name in

  Printf.printf "Receive workspace event %a to %a\n"
    log_change change
    log_wks_name current;

  begin match change, current_name_opt with
  | Focus, Some name ->
    (* We exec the process with no-startup-id argument to prevent
       notification and the clock cursor  *)
    Configuration.load_values ini name "on_focus"
    |> List.fold_left (Actions.launch `NoStartupId) Actions.create
    |> Actions.apply conn
  | Init, Some name ->
    (* If there is a swallow option, we run it in first *)
    let state = Configuration.load_values ini name "on_init_swallow_class"
    |> List.fold_left (fun a b -> Actions.swallow b a) Actions.create
    in
    (* Do not run no-startup-id : we want the application to be launched on
       this workspace *)
    Configuration.load_values ini name "on_init"
    |> List.fold_left (Actions.launch `StartupId) state
    |> Actions.apply conn

  | _ -> Lwt.return Actions.empty
  end

end

let window_event conn {I3ipc.Event.change; I3ipc.Event.container} ini : Actions.answer Lwt.t = begin

  let exec_tree workspace f state  = begin
    let open Layout in
    begin match switch_layout workspace.I3ipc.Reply.layout with
    | Some layout' ->
      let fake_root = I3ipc.Reply.{workspace with layout = layout'} in
      traverse f [fake_root, workspace] state
    | None ->
      (* The workspace layout is not splith nor splitv, ignoring *)
      state
    end
  end in

  let%lwt tree = I3ipc.get_tree conn in

  (* Try to identify the actual workspace. If a new window is created, the
     container is already registered in the tree, but in case of close event,
     we can't rely on the container given by the event : it does not exists
     anymore.
  *)

  let handlers w = w
  |>>=? fun workspace -> workspace.I3ipc.Reply.name
  |>>=? fun name -> Configuration.load_value ini name "layout"
  |>>=? fun layout -> match layout with
  | "binary" -> Some (Layout.binary, workspace)
  | _ -> None
  in

  begin match change with
  | I3ipc.Event.Close ->
    let current_workspace = Tree.get_focused_workspace tree in
    begin match handlers current_workspace with
    | None -> Lwt.return Actions.empty
    | Some ((_, c), workspace) ->
      let state = exec_tree workspace c Actions.create in
      Actions.apply conn state
    end
  | I3ipc.Event.New ->
    let container_workspace = Tree.get_workspace tree container in
    begin match handlers container_workspace with
    | None -> Lwt.return Actions.empty
    | Some ((n, _), workspace) ->
      let state = exec_tree workspace n Actions.create in
      Actions.apply conn state
    end
  | I3ipc.Event.Move ->
    (* Move is like a Close event followed by a New one *)
    let container_workspace = Tree.get_workspace tree container
    and current_workspace = Tree.get_focused_workspace tree in
    (* Clean the current workspace *)
    let state = begin match handlers current_workspace with
    | Some ((_, c), workspace) -> exec_tree workspace c Actions.create
    | None -> Actions.create
    end in
    (* Insert the container in the new one *)
    begin match handlers container_workspace with
    | None -> Lwt.return Actions.empty
    | Some ((n, _), workspace) ->
      let state = exec_tree workspace n state in
      Actions.apply conn state
    end
  | _ -> Lwt.return Actions.empty
  end
end

let pp_error format = begin function
| I3ipc.No_IPC_socket -> Format.fprintf format "No_IPC_socket"
| I3ipc.Bad_magic_string str -> Format.fprintf format "Bad_magic_string %s" str
| I3ipc.Unexpected_eof -> Format.fprintf format "Unexpected_eof"
| I3ipc.Unknown_type _t -> Format.fprintf format "Unknown_type"
| I3ipc.Bad_reply str -> Format.fprintf format "Bad_reply %s" str
end

let rec event_loop configuration conn = begin

  begin match%lwt I3ipc.next_event conn with
  | exception I3ipc.Protocol_error err ->
    (* On error, log to stderr then loop *)
    Format.eprintf "%a\n%!" pp_error err;
    (event_loop[@tailcall]) configuration conn
  | I3ipc.Event.Workspace wks ->
    let%lwt _result = workspace_event conn wks configuration in
    (event_loop[@tailcall]) configuration conn
  | I3ipc.Event.Window w ->
    let%lwt _result = window_event conn w configuration in
    (event_loop[@tailcall]) configuration conn
  | _ ->
    (* This should not happen, we did not subscribe to other events *)
    (event_loop[@tailcall]) configuration conn
  end

end

let main =

  let cfg, _ = Args.argparse (Args.default_conf ()) "i3_workspaces" Sys.argv in

  if not (Sys.file_exists cfg.config) then (
    Printf.eprintf "Configuration file %s not found\nExciting\n%!" cfg.config;
    exit 1
  );
  (* Load the ini file *)
  begin match Configuration.load cfg.config with
  | None -> exit 1
  | Some config ->
    let%lwt conn = I3ipc.connect () in

    let%lwt reply = I3ipc.subscribe conn [Workspace ; Window] in
    if reply.success then
      event_loop config conn
    else
      Lwt.return_unit
  end

let () = Lwt_main.run main
