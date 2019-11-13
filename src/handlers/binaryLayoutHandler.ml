open Common
open I3ipc.Reply

include DefaultHandler

type t = Configuration.t

type traversal = Actions.t -> node -> node -> (Actions.t * node list)

let switch_layout = begin function
  | SplitH -> Some SplitV
  | SplitV -> Some SplitH
  | _ -> None
end

let rec get_singles acc t = begin match t.nodes with
  | single::[] -> (get_singles[@tailcall]) (single::acc) single
  | _ -> acc
end

let rec reduce container state = begin function
  | [] -> state, container
  | hd::tl ->
    begin match hd.layout with
    | SplitV ->
        let state = Actions.exec ~focus:container "move left" state in
        (reduce [@tailcall]) container state tl
    | SplitH ->
        let state = Actions.exec ~focus:container "move up" state in
        reduce container state tl
    | _ -> state, container
    end
end

(** Simplify the tree by removing all the containers which contains a single
child *)
let reduce_tree state _ container = begin
  begin match get_singles [] container with
  | leaf::tl ->
    let state, child = reduce leaf state tl in
    (* If the container is a workspace, restore its original layout by
       splitting hist last child, it has been destroyed when we move the last
       child out of his parent *)
    let state' = begin match container.nodetype with
    | Workspace -> Actions.split child (child.layout) state
    | _ -> state
    end in
    (state', [child])
  | [] ->
    (state, container.nodes)
  end

end

let check_split container state orientation = begin
  List.fold_left (fun (state, acc) n ->
    begin match n.layout == orientation, n.nodes with
    | _, [] ->
      (* This is the last container, and it is directly under a node with
         many childs, we split *)
      Actions.split n orientation state, acc
    | false, _ ->
      (* The node is not final, but the layout is not the good one. We change
         it *)
      let n' = {n with layout = orientation} in
      Actions.layout n orientation state, n'::acc
    | true, _ ->
      (* The node already has the right orientation, and is not a final
         container : we keep it unchanged *)
      state, n::acc
    end
  )  (state, []) container.nodes
end

let binary_tree state parent container = begin
  begin match container.nodes, switch_layout container.layout with
  (* If the node has no childs, ignore it *)
  | [], _
  | _, None -> state, []
  (* If the node has only one child, just change the layout *)
  | hd::[], Some new_layout ->
      if parent.layout == container.layout then (
        Actions.layout container new_layout state, [{hd with layout = new_layout}]
      ) else (
        state, [hd]
      )
  (* If there is more than one child, split all the descendors *)
  | _, Some new_layout ->
      check_split container state new_layout
  end
end

let rec traverse (f:traversal) nodes state: Actions.t = begin match nodes with
| [] -> (* no nodes, just return *) state
| ((parent:node), (hd:node))::tl ->
  let (state, childs) = f state parent hd in
  (* Add the parent information to all childs *)
  let childs' = List.map (fun t -> hd, t) childs in
  (traverse[@tailcall]) f (List.append tl childs') state
end

let (|>>=?) opt f = Option.bind ~f opt

(** Check if we should manage this workspace *)
let handlers ini workspace = workspace.I3ipc.Reply.name
|>>=? fun name -> Configuration.load_value ini name "layout"
|>>=? fun layout -> match layout with
| "binary" -> Some true
| _ -> None

let window_create ini ~workspace ~container:_ state = begin
  match handlers ini workspace with
  | None -> Lwt.return state
  | Some _ ->
    begin match switch_layout workspace.I3ipc.Reply.layout with
    | Some layout' ->
      let fake_root = I3ipc.Reply.{workspace with layout = layout'} in
      traverse binary_tree [fake_root, workspace] state
      |> Lwt.return
    | None ->
      (* The workspace layout is not splith nor splitv, ignoring *)
      Lwt.return state
    end
end

let window_close ini ~workspace ~container:_ state = begin
  match handlers ini workspace with
  | None -> Lwt.return state
  | Some _ ->
    begin match switch_layout workspace.I3ipc.Reply.layout with
    | Some layout' ->
      let fake_root = I3ipc.Reply.{workspace with layout = layout'} in
      traverse reduce_tree [fake_root, workspace] state
      |> Lwt.return
    | None ->
      (* The workspace layout is not splith nor splitv, ignoring *)
      Lwt.return state
    end
end
