open I3ipc

(** Command line arguments *)
module Args = struct
  type t = {
    config : string [@short "-c"]
      (** Specify the path to the configuration file.*)
  } [@@deriving argparse]

  let check_file env path = begin
    try
      let env_value = Unix.getenv env in
      let file = env_value ^ "/" ^ path ^ "config" in
      if Sys.file_exists file then
        Some file
      else
        None
    with Not_found -> None
  end

  (** Try to look for the default environment *)
  let default_conf () = begin
    match check_file "XDG_CONFIG_HOME" "i3_workspaces/" with
    | Some f -> {config = f}
    | None -> begin
      match check_file "HOME" ".config/i3_workspaces/" with
      | Some f -> {config = f}
      | None -> {config = ""}
    end
  end

end

(** Configuration file *)
module Configuration = struct

  type t = Inifiles.inifile

  (** Load a value from the global section *)
  let load_global conf field = begin
    try Some(conf#getval "global" field) with
    | Inifiles.Invalid_section _ -> None
    | Inifiles.Invalid_element _-> None
  end

  (** Load the value from the Configuration
    If the key does not exist, look for the global section
  *)
  let load_value conf section field = begin

    try Some (conf#getval section field) with
    | Inifiles.Invalid_element _ ->
      load_global conf field
    | Inifiles.Invalid_section _ ->
      Printf.printf "Unknown workspace %s\n%!" section;
      load_global conf field
  end

  (** Regex for extracting the variables parameters in configuration file *)
  let param = Str.regexp {|\${.+}|}

  (** Replace the given string with the values associated with key in the ini file *)
  let rec get_params t section str = begin

    match Str.search_forward param str 0 with
    | exception Not_found -> Some str
    | _ ->
      let matched = Str.matched_string str in
      let len = String.length matched in
      (* Remove the ${ } around the text *)
      let argument = String.sub matched 2 (len - 3) in
      begin match load_value t section argument with
      | None ->
          (* This should occur only in startup *)
          Printf.eprintf "Key %s not found in section [%s] nor [global]\n%!" argument section;
          None
      | Some x ->
          get_params t section (Str.replace_first param x str)
      end;
end

  (** Check the whole configuration to ensure that each variable use in a
      section is defined somewhere *)
  let check_section conf section = begin
    let f _key value = begin match get_params conf section value with
    | None -> raise Not_found
    | Some _ -> ()
    end in
    conf#iter f section
  end

  let load f = begin
    let conf = new Inifiles.inifile f in
    let sections = conf#sects in
    (* Ensure we have a global section *)
    match List.exists ((=) "global") sections with
    | false ->
        Printf.eprintf "No [global] section found in %s\nExciting\n%!" f;
        None
    | true ->
        match List.iter (check_section conf) sections with
        | exception Not_found -> None
        | _ -> Some conf
  end


end

(** Some standard function for Option type *)
module Option = struct

  let map ~f = function
  | None -> None
  | Some x -> Some (f x)

  let bind ~f = function
  | None -> None
  | Some x -> f x

end

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
