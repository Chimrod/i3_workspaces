

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
    let%lwt _result = Handlers.Registry.workspace_event conn wks in
    (event_loop[@tailcall]) configuration conn
  | I3ipc.Event.Window w ->
    let%lwt _result = Handlers.Registry.window_event conn w in
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

    Handlers.Registry.add config (module Handlers.LoggerHandler);
    Handlers.Registry.add config (module Handlers.BinaryLayoutHandler);
    Handlers.Registry.add config (module Handlers.ExecHandler);
    Handlers.Registry.add config (module Handlers.Persistence);

    let%lwt conn = I3ipc.connect () in

    let%lwt reply = I3ipc.subscribe conn [Workspace ; Window] in
    if reply.success then
      event_loop config conn
    else
      Lwt.return_unit
  end

let () = Lwt_main.run main
