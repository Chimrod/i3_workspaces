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

(** General traverse tree function which return the workspace which contains a
    window match a given predicate.
*)
let traverse f (root:t) = begin

  let rec match_container wks (nodes: t list) = begin match nodes with
  | [] -> false
  | hd::tl ->
    if f hd then
      true
    else
      let nodes' = List.rev_append hd.I3ipc.Reply.nodes tl in
      (match_container [@tailcall]) wks nodes'
  end in

  let rec traverse (nodes:t list) = begin
    begin match nodes with
    | [] -> None
    | hd::tl ->

      begin match hd.nodetype with
      | Workspace ->
        begin match match_container hd (hd::hd.nodes) with
        | true -> Some hd
        | false -> (traverse [@tailcall]) tl
        end
      | Floating_con | Dockarea ->  (traverse[@tailcall]) tl
      | _ -> (traverse[@tailcall]) (List.rev_append hd.nodes tl)
      end
    end
  end in
  traverse [root]
end

let get_workspace (t:t) (container:t) = begin
  traverse (fun c -> c.I3ipc.Reply.id = container.I3ipc.Reply.id) t
end

let get_focused_workspace (t:t) = begin
  traverse (fun c -> c.I3ipc.Reply.focused) t
end
