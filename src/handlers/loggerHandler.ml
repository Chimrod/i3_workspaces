include DefaultHandler.M

let workspace_focus _ ~workspace:_ name state = begin
  Printf.printf "Receive workspace event Focus on %s\n"
    name;
  state
end

let workspace_init _ ~workspace:_ name state = begin
  Printf.printf "Receive workspace event Init on %s\n"
    name;
  state
end
