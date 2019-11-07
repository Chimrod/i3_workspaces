open Common

type t = I3ipc.Reply.node

let (|>>=?) opt f = Option.bind ~f opt

let opt_name = function
  | Some name -> name
  | None -> "?"

(** Show all the links from one node to his childs *)
let show_links formatter (t:t) = begin

  Format.pp_print_list ~pp_sep:(fun _ _ -> ()) (fun f (subnode:t) ->
    Format.fprintf f "\n%s -> %s"
      t.id
      subnode.id
  ) formatter t.nodes
end

let rec pp_print_node formatter (t:t) = begin

  (* The window name *)
  let w_name : string =
    t.window_properties
    |>>=? (fun f -> f.title)
    |> opt_name
    in

  let print_attrs f (t:t) = begin match t.nodetype with
  | Root ->
    Format.fprintf f "label=root style=filled fillcolor=\"/accent6/1\""
  | Output ->
    Format.fprintf f "style=filled fillcolor=\"/accent6/2\""
  | Con ->
    Format.fprintf f "label=\"%s - %a\r%s\" style=filled fillcolor=\"/accent6/3\" "
      w_name
      I3ipc.Reply.pp_node_layout t.layout
      t.id
  | Floating_con ->
    Format.fprintf f "style=filled fillcolor=\"/accent6/4\""
  | Workspace ->
    Format.fprintf f "label=\"%s - %a - %s\" style=filled fillcolor=\"/accent6/5\""
      (opt_name t.name)
      I3ipc.Reply.pp_node_layout t.layout
      t.id
  | Dockarea ->
    Format.fprintf f "style=filled fillcolor=\"/accent6/6\""
  end in

  Format.fprintf formatter "\n%s [%a]%a%a"
    t.id
    print_attrs t
    show_links t
    (Format.pp_print_list ~pp_sep:(fun _ _ -> ()) pp_print_node) t.nodes

end

let to_dot formatter t = begin
  Format.fprintf formatter "digraph G {\
  node [shape=record];\
  %a\
  }"
    pp_print_node t
end

let to_dot tree name = begin
  let channel = Stdlib.open_out name in
  let formatter = Format.formatter_of_out_channel channel in
  to_dot formatter tree;
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
