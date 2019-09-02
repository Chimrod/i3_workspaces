type t = {
  config : string [@short "-c"]
  (** Specify the path to the configuration file.

  By default, search for ${XDG_CONFIG_HOME}/i3_workspaces/config*)
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

