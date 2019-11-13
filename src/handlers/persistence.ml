open Common

include DefaultHandler

type t = Configuration.t * Xcb.connexion

let create_window connexion screen width height = begin
  Xcb.create_window
    connexion
    ~depth:(screen.Xcb.root_depth)
    ~parent:(screen.Xcb.root)
    ~x:10
    ~y:10
    ~width
    ~height
    ~border:0
    1
    ~visual:(screen.root_visual)
    [
      Back_pixel (screen.white_pixel);
      Event_mask ([Exposure; Key_press; Structure_notify]);
    ]
end

let init conf = begin
  match Xcb.connect () with
  |  Some connexion -> Some (conf, connexion)
  |  None -> None
end

let window_close (ini, connexion) ~workspace ~container state =
  begin match workspace.I3ipc.Reply.nodes with
  | _::_ ->  Lwt.return state
  | [] -> Lwt.return state

  end
