open I3ipc

let (|>>?) opt f = Option.bind ~f opt

let change_workspace {I3ipc.Event.change; I3ipc.Event.current; _} ini = begin

  let workspace_opt = current in

  let launch line workspace_opt = begin
    workspace_opt
    |>>? fun workspace -> workspace.I3ipc.Reply.name
    |>>? fun name -> Configuration.load_value ini name line
    |>>? fun value -> (* Load the command to run *)
      (* Replace variables in command *)
      Configuration.get_params ini name value
      |> Option.map ~f:(fun command ->
        let process = Lwt_process.shell command in
        Lwt_process.exec process
      )
  end in

  begin match change with
  | Focus -> launch "on_focus" workspace_opt
  | Init -> launch "on_init" workspace_opt
  | _ -> None
  end

end

let show_error = begin function
  | No_IPC_socket -> Printf.eprintf "No_IPC_socket error\n%!"
  | Bad_magic_string str -> Printf.eprintf "Bad_magic_string %s\n%!" str
  | Unexpected_eof -> Printf.eprintf "Unexpected_eof\n%!"
  | Unknown_type _num -> Printf.eprintf "Unknown_type\n%!"
  | Bad_reply str -> Printf.eprintf "Bad_reply %s\n%!" str
end

let rec event_loop configuration conn = begin

  (** Wait for the next Event
   If an error occur, log it, and wait again
   *)
  let rec get_event () = begin
    try%lwt I3ipc.next_event conn with
    | I3ipc.Protocol_error err ->
      show_error err;
      get_event ()
  end in

  begin match%lwt get_event () with
  | I3ipc.Event.Workspace wks ->
    let _result = change_workspace wks configuration in
    event_loop configuration conn
  | _ -> event_loop configuration conn
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
  | None ->
      exit 1
  | Some config ->
    let%lwt conn = I3ipc.connect () in

    let%lwt reply = I3ipc.subscribe conn [Workspace] in
    if reply.success then
      event_loop config conn
    else
      Lwt.return_unit
  end

let () = Lwt_main.run main
