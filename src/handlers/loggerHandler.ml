include DefaultHandler

let workspace_focus _ _ name state = begin
  Printf.printf "Receive workspace event Focus on %s\n"
    name;
  state
end

let workspace_init _ _ name state = begin
  Printf.printf "Receive workspace event Init on %s\n"
    name;
  state
end
