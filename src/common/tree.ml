type t = I3ipc.Reply.node

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

