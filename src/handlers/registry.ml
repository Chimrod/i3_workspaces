open Common

module type HANDLER = sig

  type t

  val init: Configuration.t -> t option

  (** Function to call on workspace change *)
  val workspace_focus: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t Lwt.t

  val workspace_init: t -> workspace:I3ipc.Reply.node -> string -> Common.Actions.t -> Common.Actions.t Lwt.t

  val window_create: t -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t Lwt.t

  val window_close: t -> [`Move | `Close] -> workspace:I3ipc.Reply.node -> container:I3ipc.Reply.node -> Common.Actions.t -> Common.Actions.t Lwt.t
end

(** Existancial type which associate the module with the given type *)
type handler =
    H : 'a * (module HANDLER with type t = 'a) -> handler

let modules = ref []

let add ini (module M : HANDLER) = begin
  match M.init ini with
  | None -> ()
  | Some init -> modules := H (init, (module M)) :: (!modules)
end

let get_handlers () = ! modules

let workspace_event conn {I3ipc.Event.change; I3ipc.Event.current; _} = begin

  let call_workspace_focus workspace name state handler = begin
    (* let the ocaml magic operate !

       the type handler is defined with a constraint on the module. The
       compiler know that `init` match H.t and can be used inside the call. We
       just have to decompose the tuple :
    *)
    let H (init, (module H)) = handler in
    H.workspace_focus init ~workspace name state
  end

  and call_workspace_init workspace name state handler = begin
    let H (init, (module H)) = handler in
    H.workspace_init init ~workspace name state
  end

  in

  begin match current with
    | None -> Lwt.return Actions.empty
    | Some workspace ->
      begin match workspace.I3ipc.Reply.name with
        | None -> Lwt.return Actions.empty
        (* Ensure we have a workspace and a name *)
        | Some name ->
          begin match change with
            | Focus ->
              let%lwt state = get_handlers ()
                              |> Lwt_list.fold_left_s (call_workspace_focus workspace name) Actions.create
              in
              Actions.apply conn state
            | Init ->
              let%lwt state = get_handlers ()
                              |> Lwt_list.fold_left_s (call_workspace_init workspace name) Actions.create
              in
              Actions.apply conn state
            | _ -> Lwt.return Actions.empty
          end
      end
  end
end

let window_event conn {I3ipc.Event.change; I3ipc.Event.container} = begin

  let%lwt tree = I3ipc.get_tree conn in


  let call_window_close workspace container ev state handler = begin
    let H (init, (module H)) = handler in
    H.window_close init ev ~workspace ~container state
  end

  and call_window_create workspace container state handler = begin
    let H (init, (module H)) = handler in
    H.window_create init ~workspace ~container state
  end in

  begin match change with
    | I3ipc.Event.Close ->
      (* On close event, we try to find the focused workspace, as the container given
         by i3 does not exists anymore in the tree *)
      let focused_workspace = Common.Tree.get_focused_workspace tree in
      begin match focused_workspace with
        | None -> Lwt.return Actions.empty
        | Some workspace ->
          let%lwt state = get_handlers ()
                          |> Lwt_list.fold_left_s (call_window_close workspace container `Close) Actions.create
          in
          Actions.apply conn state
      end
    | I3ipc.Event.New ->
      let workspace = Common.Tree.get_workspace tree container in
      begin match workspace with
        | None -> Lwt.return Actions.empty
        | Some workspace ->
          let%lwt state = get_handlers ()
                          |> Lwt_list.fold_left_s (call_window_create workspace container) Actions.create
          in
          Actions.apply conn state
      end
    | I3ipc.Event.Move ->
      (* Move is like a Close event followed by a New one *)

      let handlers = get_handlers () in

      let focused_workspace = Common.Tree.get_focused_workspace tree in
      let current_workspace = Common.Tree.get_workspace tree container in
      let%lwt state = begin match focused_workspace with
        | None -> Lwt.return Actions.create
        | Some workspace ->
          Lwt_list.fold_left_s (call_window_close workspace container `Move) Actions.create handlers
      end in
      let%lwt state' = begin match current_workspace with
        | None -> Lwt.return state
        | Some workspace ->
          Lwt_list.fold_left_s (call_window_create workspace container) state handlers
      end in
      Actions.apply conn state'
    | _ ->  Lwt.return Actions.empty
  end

end
