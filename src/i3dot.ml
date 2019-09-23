let to_dot tree name = begin
  let channel = Stdlib.open_out name in
  let formatter = Format.formatter_of_out_channel channel in
  Tree.to_dot formatter tree;
  Stdlib.close_out channel
end

let main =

  let%lwt conn = I3ipc.connect () in
  let%lwt tree = I3ipc.get_tree conn in
  begin match Tree.get_focused_workspace tree with
  | None ->
    Printf.eprintf "No workspace found\n%!";
    exit 1
  | Some workspace ->
    let time = string_of_float @@ ceil @@ Unix.time () in
    let name = workspace.I3ipc.Reply.id ^ "_" ^ time ^ "gv" in
    to_dot workspace name;
    let command = Lwt_process.shell ("dot -Tpng -O " ^ name) in
    let%lwt _status = Lwt_process.exec command in
    Lwt.return @@ Unix.unlink name
  end

let () = Lwt_main.run main
