open I3ipc

let (|>>?) opt f = Option.bind ~f opt
let (|>>=?) opt f = begin match opt with
    | None -> Lwt.return_none
    | Some v -> Lwt.return_some (f v)
end

let swallow conn class_name : Reply.command_outcome list option Lwt.t = begin
  let%lwt command = Lwt_io.with_temp_file ~prefix:"i3_workspaces" (
    fun (temp_file, channel) ->
    let%lwt () = Lwt_io.fprintf channel {|{"swallows": [{"class": "%s"}]}|} class_name in
    let%lwt () = Lwt_io.close channel in
    let content = Lwt_io.lines_of_file temp_file in
    let%lwt () = Lwt_stream.iter print_endline content in
    let%lwt reply = (I3ipc.command conn ("append_layout " ^ temp_file)) in
    Lwt.return reply
  ) in
  Lwt.return_some command

end

let change_workspace conn {I3ipc.Event.change; I3ipc.Event.current; _} ini = begin

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

       current
  |>>=? fun workspace -> workspace.I3ipc.Reply.name
  |>>=? fun name -> begin match change with
    | Focus ->
      launch name "on_focus" (fun c ->
        (* We exec the process with no-startup-id argument to prevent
           notification and the clock cursor  *)
        I3ipc.command conn ("exec --no-startup-id " ^ c))
    | Init -> (
      (* Is there a swallow option ? *)
      let%lwt swallow = Configuration.load_value ini name "on_init_swallow_class"
      |>>=? k -> swallow conn k in
      launch name "on_init" (fun c ->
        (* Do not run no-startup-id : we want the application to be launched on
           this workspace *)
        I3ipc.command conn ("exec " ^ c))
      )
    | _ -> Lwt.return_none
  end

end

let show_error = begin function
  | No_IPC_socket ->        Printf.eprintf "No_IPC_socket error\n%!"
  | Bad_magic_string str -> Printf.eprintf "Bad_magic_string %s\n%!" str
  | Unexpected_eof ->       Printf.eprintf "Unexpected_eof\n%!"
  | Unknown_type num ->    Printf.eprintf "Unknown_type : %s\n%!" (Stdint.Uint32.to_string num)
  | Bad_reply str ->        Printf.eprintf "Bad_reply %s\n%!" str
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
    let _result = change_workspace conn wks configuration in
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
