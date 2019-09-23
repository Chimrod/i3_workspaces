open I3ipc

let (|>>?) opt f = Option.bind ~f opt
let (|>>=?) opt f = begin match opt with
    | None -> Lwt.return_none
    | Some v -> Lwt.return_some (f v)
end

let swallow conn class_name : Reply.command_outcome list Lwt.t = begin

  Lwt_io.with_temp_file ~prefix:"i3_workspaces" (
    fun (temp_file, channel) ->
    Printf.printf "\tSwallowing class %s\n%!" class_name;
    let%lwt () = Lwt_io.fprintf channel {|{"swallows": [{"class": "%s"}]}|} class_name in
    let%lwt () = Lwt_io.close channel in
    I3ipc.command conn ("append_layout " ^ temp_file)
  )

end

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

let change_workspace conn {I3ipc.Event.change; I3ipc.Event.current; I3ipc.Event.old} ini = begin

  let launch name line f = begin
    let process = Configuration.load_value ini name line
    |>>? fun value -> (* Load the command to run *)
      (* Replace variables in command *)
      Configuration.get_params ini name value
      |> Option.map ~f
    in match process with
    | None -> Lwt.return_none
    | Some p -> Lwt.map (fun x -> Some x) p
  end in

  let current_name_opt: string option = current
  |>>? fun workspace -> workspace.I3ipc.Reply.name in

  Printf.printf "Receive event %a from %a to %a\n"
    log_change change
    log_wks_name old
    log_wks_name current;

  begin match change, current_name_opt with
  | Focus, Some name ->
      launch name "on_focus" (fun c ->
        (* We exec the process with no-startup-id argument to prevent
           notification and the clock cursor  *)
        Printf.printf "\tRunning %s\n%!" c;
        I3ipc.command conn ("exec --no-startup-id " ^ c))
  | Init, Some name -> (
      (* Is there a swallow option ? *)
      let%lwt res =
      match Configuration.load_value ini name "on_init_swallow_class" with
      | None -> Lwt.return_unit
      | Some _class -> Lwt.bind (swallow conn _class) (fun _ -> Lwt.return_unit)
      in

      launch name "on_init" (fun c ->
        (* Do not run no-startup-id : we want the application to be launched on
           this workspace *)
        Printf.printf "Running %s\n%!" c;
        I3ipc.command conn ("exec " ^ c))
      )
  | _, _ ->
      Lwt.return_none
  end

end

let show_error = begin function
  | No_IPC_socket ->        Printf.eprintf "No_IPC_socket error\n%!"
  | Bad_magic_string str -> Printf.eprintf "Bad_magic_string %s\n%!" str
  | Unexpected_eof ->       Printf.eprintf "Unexpected_eof\n%!"
  | Unknown_type num ->     Printf.eprintf "Unknown_type : %s\n%!" (Stdint.Uint32.to_string num)
  | Bad_reply str ->        Printf.eprintf "Bad_reply %s\n%!" str
end

let rec event_loop configuration conn = begin

  begin match%lwt I3ipc.next_event conn with
  | exception I3ipc.Protocol_error err ->
    (* On error, log to stderr then loop *)
    Format.eprintf "%a\n%!" I3ipc.pp_protocol_error err;
    event_loop configuration conn
  | I3ipc.Event.Workspace wks ->
    let%lwt _result = change_workspace conn wks configuration in
    event_loop configuration conn
  | _ ->
    (* This should not happen, we did not subscribe to other events *)
    event_loop configuration conn
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

    let%lwt reply = I3ipc.subscribe conn [Workspace] in
    if reply.success then
      event_loop config conn
    else
      Lwt.return_unit
  end

let () = Lwt_main.run main
