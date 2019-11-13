include DefaultHandler

type t = Configuration.t

let workspace_focus _ ~workspace:_ name state = begin
  Printf.printf "Receive workspace event Focus on %s\n"
    name;
  Lwt.return state
end

let workspace_init _ ~workspace:_ name state = begin
  Printf.printf "Receive workspace event Init on %s\n"
    name;
  Lwt.return state
end
