open Common

include DefaultHandler

type t = {
  conf: Configuration.t ;
  connexion: Xcb.connexion ;
  screen: Xcb.screen;
  mutable windows: Xcb.id list
}

let create_window connexion (screen:Xcb.screen) width height = begin
  Xcb.create_window
    connexion
    ~depth:None
    ~parent:(screen.Xcb.root)
    ~x:10
    ~y:10
    ~width
    ~height
    ~border:0
    1
    ~visual:None
    [
      Back_pixel (screen.white_pixel);
    ]
end

let init conf = begin
  match Xcb.connect () with
  |  Some connexion ->
    let screen =  List.hd @@ Xcb.get_screens connexion in
     Some ({conf; connexion; screen; windows=[]})
  |  None -> None
end

(** Check if the given container has been declared in the registered windows *)
let check_registered_window t container = begin
  match container.I3ipc.Reply.window with
  | None -> None
  | Some id ->
  let win_id = string_of_int id in
  List.find_opt (fun id -> String.equal (Xcb.string_of_id id) win_id) t.windows
end

(** Remove the given window id from the registered list *)
let remove_window t id event = begin
  let win_id = Xcb.string_of_id id in
  t.windows <- List.filter (fun id -> not @@ String.equal (Xcb.string_of_id id) win_id) t.windows;
  match event with
  | `Close -> ()
  | _ ->
  (* Destroy the window if it is moved out of it workspace *)
  let _ = Xcb.destroy_window t.connexion id in
  let _ = Xcb.flush t.connexion in
  ()
end

(** Handle a close event
    The function created an empty window if the container does not contains
    anymore windo.
*)
let handle_event t workspace state = begin
  match Tree.has_container workspace with
  | true ->  Lwt.return state
  | false ->

  match create_window t.connexion t.screen 100 100 () with
  | None -> Lwt.return state
  | Some id ->
  let _ = Xcb.change_property_string t.connexion id Replace Wm_class "i3_workspaces"
  and _ = Xcb.change_property_string t.connexion id Replace Wm_name "i3_workspaces"
  and _ = Xcb.map_window t.connexion id in
  let _ = Xcb.flush t.connexion in
  (* Add the window in the list *)
  t.windows <- id::t.windows;
  Lwt.return state
end


let window_close t event ~workspace ~(container:I3ipc.Reply.node) state = begin

  (** Check if the target window has been created by ourself and destroy it if need *)
  match check_registered_window t container with
  | Some id -> remove_window t id event; Lwt.return state
  | None ->

  match workspace.I3ipc.Reply.name with
  | None -> Lwt.return state
  | Some name ->

  match event, Configuration.load_value t.conf name "persistence" with
  | `Close, Some "on_last_close" -> handle_event t workspace state
  | `Close, Some "on_last_move"  -> handle_event t workspace state
  | `Move,  Some "on_last_move"  -> handle_event t workspace state
  | _, _ -> Lwt.return state
end

let window_create t ~workspace ~container state =

  match workspace.I3ipc.Reply.name with
  | None -> Lwt.return state
  | Some name ->

  match Configuration.load_value t.conf name "persistence" with
  | None -> Lwt.return state
  | Some _ ->

  (* If the window is the one we create, ignore it ! *)
  match check_registered_window t container with
  | Some _ -> Lwt.return state
  | None ->

  (* Search in all the existings windows for one created by the application,
     and destroy it if we found one *)
  ignore @@ Tree.traverse (fun con' ->
    match con'.I3ipc.Reply.window with
    | None -> false
    | Some id ->
      let win_id = string_of_int id in
      match List.find_opt (fun w -> String.equal win_id (Xcb.string_of_id w)) t.windows with
      | None -> false
      | Some w ->
        remove_window t w `None;
        true
  ) workspace;
  Lwt.return state
