open Ctypes
open Foreign

include Bindings.Types(Bindings_types)

module XcbHelper = struct


  let (|.->) str field =
    (!@( str |-> field))


  type 'a cookie = unit -> 'a
end

include XcbHelper

type id = Unsigned.uint32

let string_of_id = Unsigned.UInt32.to_string

(** The connection to the server.

    The type is a tuple containing the connection given by xcb, and the file
    descriptor (used for polling events (used for polling events))
*)
type connexion = c_connexion * Lwt_unix.file_descr

let _connect =
  foreign "xcb_connect" (string_opt @-> ptr_opt int @-> returning c_connexion)

let _get_fd =
  foreign "xcb_get_file_descriptor" (c_connexion @-> (returning int))

(** Get the file descriptor for the connexion *)
let get_fd conn =
  Unix_representations.file_descr_of_int @@ _get_fd conn

let connection_has_error =
  foreign "xcb_connection_has_error" (c_connexion @-> (returning bool))

let _free =
  foreign "free" (ptr void @-> returning void)

let connect ?display ?screen () = begin
  let screenp = match screen with
  | None -> None
  | Some v -> Some (allocate int v) in
  let connection = _connect display screenp in
  if connection_has_error connection then
    None
  else
    let fd = Lwt_unix.of_unix_file_descr @@ get_fd connection in
    Some (connection, fd)
end

let _get_setup =
  foreign "xcb_get_setup" (c_connexion @-> returning (ptr setup_t))

let _setup_roots_iterator =
  foreign "xcb_setup_roots_iterator" (ptr setup_t @-> (returning screen_iterator))

let _generate_id =
  foreign "xcb_generate_id" (c_connexion @-> (returning id))

type void_cookie_t = unit ptr
let void_cookie_t: void_cookie_t typ = ptr void

let _request_check =
  foreign "xcb_request_check" (c_connexion
  @-> void_cookie_t
  @-> returning (ptr_opt generic_error))

let request_check value conn c = begin match _request_check conn c with
  | None -> Some value
  | Some x ->
    Printf.printf "error_code : %d\n" (!@(x |-> code));
    None
end

let _map_window =
  foreign "xcb_map_window_checked" (c_connexion
    @-> id (* wid *)
    @-> (returning void_cookie_t))

let _flush =
  foreign "xcb_flush" (c_connexion
    @-> (returning int))

let _create_window =
  foreign "xcb_create_window_checked" (c_connexion
    @-> uint8_v    (* depth *)
    @-> id         (* wid *)
    @-> id         (* parent *)
    @-> int16_t    (* x *)
    @-> int16_t    (* y *)
    @-> uint16_v   (* width *)
    @-> uint16_v   (* height *)
    @-> uint16_v   (* border_width *)
    @-> uint16_v   (* class *)
    @-> visualid_t (* visual *)
    @-> uint32_v   (* value mask *)
    @-> ptr void   (* value list *)
    @-> (returning void_cookie_t))


let foreign_destroy_window =
  foreign "xcb_destroy_window_checked" (c_connexion
    @-> id         (* wid *)
    @-> (returning void_cookie_t))

let _change_property_str =
  foreign "xcb_change_property_checked" (c_connexion
    @-> uint8_v
    @-> id         (* wid *)
    @-> xcb_atom_t
    @-> xcb_atom_t
    @-> uint8_v
    @-> uint32_v
    @-> string   (* data *)
    @-> (returning void_cookie_t))

type key_event = {
  key: int;
  root: id;
  event: id;
}

type mouse_event = {
  root: id;
  child: id;
  position: int * int;
}

type expose_event = {
  window: id;
  pos: int * int;
  width: int;
  height: int;
}

type destroy_event = {
  event: id;
  window: id;
}

type event_result =

(* Key_press events *)

| Key_press of key_event
| Key_release of key_event
| Button_press of mouse_event
| Button_release of mouse_event
| Motion_notify of mouse_event
| Enter_notify (* 7 *)
| Leave_notify
| Focus_in
| Focus_out
| Keymap_notify

(* Exposure events *)

| Expose of expose_event
| Graphics_exposure
| No_exposure
| Visibility_notify
| Create_notify

(* Structure_notify evens *)

| Destroy_notify of destroy_event
| Unmap_notify (* 18 *)
| Map_notify
| Map_request
| Reparent_notify
| Configure_notify
| Configure_request (* 23 *)
| Gravity_notify
| Resize_request (* 25 *)
| Circulate_notify (* 26 *)
| Circulate_request
| Property_notify
| Selection_clear (* 29 *)

let event_mask_number = function
| Xcb_types.No_event ->               Events.mask_no_event
| Xcb_types.Key_press ->              Events.mask_key_press
| Xcb_types.Key_release ->            Events.mask_key_release
| Xcb_types.Button_press ->           Events.mask_button_press
| Xcb_types.Button_release ->         Events.mask_button_release
| Xcb_types.Enter_window ->           Events.mask_enter_window
| Xcb_types.Leave_window ->           Events.mask_leave_window
| Xcb_types.Pointer_motion ->         Events.mask_pointer_motion
| Xcb_types.Pointer_motion_hint ->    Events.mask_pointer_motion_hint
| Xcb_types.Button_1_motion ->        Events.mask_button_1_motion
| Xcb_types.Button_2_motion ->        Events.mask_button_2_motion
| Xcb_types.Button_3_motion ->        Events.mask_button_3_motion
| Xcb_types.Button_4_motion ->        Events.mask_button_4_motion
| Xcb_types.Button_5_motion ->        Events.mask_button_5_motion
| Xcb_types.Button_motion ->          Events.mask_button_motion
| Xcb_types.Keymap_state ->           Events.mask_keymap_state
| Xcb_types.Exposure ->               Events.mask_exposure
| Xcb_types.Visibility_change ->      Events.mask_visibility_change
| Xcb_types.Structure_notify ->       Events.mask_structure_notify
| Xcb_types.Resize_redirect ->        Events.mask_resize_redirect
| Xcb_types.Substructure_notify ->    Events.mask_substructure_notify
| Xcb_types.Substructure_redirect ->  Events.mask_substructure_redirect
| Xcb_types.Focus_change ->           Events.mask_focus_change
| Xcb_types.Property_change ->        Events.mask_property_change
| Xcb_types.Color_map_change ->       Events.mask_color_map_change
| Xcb_types.Owner_grab_button ->      Events.mask_owner_grab_button

let _f (mask, values) = begin
  let open WindowProperties in
  function
  | Xcb_types.Back_pixmap       v -> mask lor cw_back_pixmap      , v::values
  | Xcb_types.Back_pixel        v -> mask lor cw_back_pixel       , v::values
  | Xcb_types.Border_pixmap     v -> mask lor cw_border_pixmap    , v::values
  | Xcb_types.Border_pixel      v -> mask lor cw_border_pixel     , v::values
  | Xcb_types.Bit_gravity       v -> mask lor cw_bit_gravity      , v::values
  | Xcb_types.Win_gravity       v -> mask lor cw_win_gravity      , v::values
  | Xcb_types.Backing_store     v -> mask lor cw_backing_store    , v::values
  | Xcb_types.Backing_planes    v -> mask lor cw_backing_planes   , v::values
  | Xcb_types.Backing_pixel     v -> mask lor cw_backing_pixel    , v::values
  | Xcb_types.Override_redirect v -> mask lor cw_override_redirect, v::values
  | Xcb_types.Save_under        v -> mask lor cw_save_under       , v::values
  | Xcb_types.Event_mask        v ->
      let v' = List.fold_left (fun a b -> a lor (event_mask_number b)) 0 v in
      mask lor cw_event_mask, v'::values
  | Xcb_types.Dont_propagate    v -> mask lor cw_dont_propagate  , v::values
  | Xcb_types.Colormap          v -> mask lor cw_colormap        , v::values
  | Xcb_types.Cursor            v -> mask lor cw_cursor          , v::values
end

(** Iterate over the screen list *)
let _screen_next =
  foreign "xcb_screen_next" (screen_iterator @-> (returning void))

type screen = {
  root: id;
  white_pixel:Xcb_types.color;
  black_pixel:Xcb_types.color;
  width_in_pixels: int;
  height_in_pixels: int;
  root_visual: visualid_t;
  root_depth: int;
}

let screen_of_c screen_t = {
  root =            (screen_t |.-> root);
  white_pixel =     (screen_t |.-> white_pixel);
  black_pixel =     (screen_t |.-> black_pixel);
  width_in_pixels = (screen_t |.-> width_in_pixels);
  height_in_pixels= (screen_t |.-> height_in_pixels);
  root_visual =     (screen_t |.-> root_visual);
  root_depth =      (screen_t |.-> root_depth);
}

let get_screens (conn, _) = begin
  let setup = _get_setup conn in
  let iterator = _setup_roots_iterator setup in

  (* get the first screen *)
  let first_screen = getf iterator data in
  let rem = getf iterator rem in

  (* load all the next screens *)
  let screens = List.init (rem - 1) (fun _ ->
    let d = getf iterator data in
    _screen_next iterator;
    screen_of_c d
  ) in
  (screen_of_c first_screen)::screens



end

let create_window (conn, _) ~depth ~parent ~x ~y ~width ~height ~border c_class ~visual values = begin


  let wid = _generate_id conn in

  (* Create the property list *)
  let mask, values = List.fold_left _f (0, []) values in
  let values' = values
    |> List.rev_map (Unsigned.UInt32.of_int)
    |> CArray.of_list uint32_t
    |> CArray.start
    |> to_voidp


  and depth' = begin match depth with
  | None -> copy_from_parent
  | Some x -> x
  end

  and visual' = begin match visual with
  | None -> copy_from_parent
  | Some x -> x
  end

  in
  let c =
    _create_window conn
      depth'
      wid
      parent
      x
      y
      width
      height
      border
      c_class
      visual'
      mask
      values'
    in fun () -> request_check wid conn c
end



let map_window (conn, _) id = begin
  let c = _map_window conn id in
  fun () -> match _request_check conn c with
    | None -> true
    | Some x ->
        Printf.printf "error_code : %d\n" (!@(x |-> code));
        false
  end

let destroy_window (conn, _) id = begin
  let c = foreign_destroy_window conn id in
  fun () -> match _request_check conn c with
    | None -> true
    | Some x ->
        Printf.printf "error_code : %d\n" (!@(x |-> code));
        false
end


let flush (conn, _) = _flush conn

(** Events *)


(** Expose event *)

let to_expose_event ev = begin
  let event' = coerce (ptr generic_event_t) (ptr expose_event_t) ev in
  {
    window = event' |.-> expose_window;
    pos = event' |.-> expose_x, event' |.-> expose_y;
    width = event' |.-> expose_width;
    height = event' |.-> expose_height;
  }

end

(** Keyboard press and release events *)

let to_key_event ev = begin
  let event' = coerce (ptr generic_event_t) (ptr input_event_t) ev in
  {
    key = event' |.-> input_detail;
    root = event' |.-> input_root;
    event = event' |.-> input_event;
  }
end

let to_mouse_event ev = begin
  let event' = coerce (ptr generic_event_t) (ptr input_event_t) ev in
  {
    position = event' |.-> input_event_x, event' |.-> input_event_y;
    root = event' |.-> input_root;
    child = event' |.-> input_child;
  }
end

let to_destroy_event ev = begin
  let event' = coerce (ptr generic_event_t) (ptr destroy_notify_event_t) ev in
  {
    event = event' |.-> destroy_event;
    window = event' |.-> _destroy_window;
  }

end

let events_mapping = begin

  let events_mapping = [
    Events.expose,        (fun ev -> Expose (to_expose_event ev));
    Events.key_press ,    (fun ev -> Key_press (to_key_event ev));
    Events.key_release,   (fun ev -> Key_release (to_key_event ev));
    Events.button_press,  (fun ev -> Button_press (to_mouse_event ev));
    Events.button_release,(fun ev -> Button_release (to_mouse_event ev));
    Events.destroy_notify,(fun ev -> Destroy_notify (to_destroy_event ev));
  ]

  in

  let table = Hashtbl.create (List.length events_mapping) in
  List.iter (fun (a, b) -> Hashtbl.add table a b) events_mapping;
  fun a -> Hashtbl.find_opt table a

end

let _wait_for_event =
  foreign "xcb_wait_for_event" (c_connexion @-> returning (ptr generic_event_t))

let ev_mask = lnot 0x80

let rec poll_event (conn, fd) = begin

  let%lwt () = Lwt_unix.wait_read fd in
  let event = _wait_for_event conn in
  let value = (event |.-> response_type) land ev_mask in

  match events_mapping value with
  | Some buider ->
    let ocaml_event = buider event in
    _free @@ to_voidp event;
    Lwt.return ocaml_event
  | None ->
    _free @@ to_voidp event;
    poll_event (conn, fd)

end

let mode_to_c = function
| Xcb_types.Append  -> WindowProperties.append
| Xcb_types.Prepend -> WindowProperties.prepend
| Xcb_types.Replace -> WindowProperties.replace

let atom_code = function
| Xcb_types.None                -> WindowProperties.none
| Xcb_types.Any                 -> WindowProperties.any
| Xcb_types.Primary             -> WindowProperties.primary
| Xcb_types.Secondary           -> WindowProperties.secondary
| Xcb_types.Arc                 -> WindowProperties.arc
| Xcb_types.Atom                -> WindowProperties.atom
| Xcb_types.Bitmap              -> WindowProperties.bitmap
| Xcb_types.Cardinal            -> WindowProperties.cardinal
| Xcb_types.Colormap            -> WindowProperties.colormap
| Xcb_types.Cursor              -> WindowProperties.cursor
| Xcb_types.Cut_buffer0         -> WindowProperties.cut_buffer0
| Xcb_types.Cut_buffer1         -> WindowProperties.cut_buffer1
| Xcb_types.Cut_buffer2         -> WindowProperties.cut_buffer2
| Xcb_types.Cut_buffer3         -> WindowProperties.cut_buffer3
| Xcb_types.Cut_buffer4         -> WindowProperties.cut_buffer4
| Xcb_types.Cut_buffer5         -> WindowProperties.cut_buffer5
| Xcb_types.Cut_buffer6         -> WindowProperties.cut_buffer6
| Xcb_types.Cut_buffer7         -> WindowProperties.cut_buffer7
| Xcb_types.Drawable            -> WindowProperties.drawable
| Xcb_types.Font                -> WindowProperties.font
| Xcb_types.Integer             -> WindowProperties.integer
| Xcb_types.Pixmap              -> WindowProperties.pixmap
| Xcb_types.Point               -> WindowProperties.point
| Xcb_types.Rectangle           -> WindowProperties.rectangle
| Xcb_types.Resource_manager    -> WindowProperties.resource_manager
| Xcb_types.Rgb_color_map       -> WindowProperties.rgb_color_map
| Xcb_types.Rgb_best_map        -> WindowProperties.rgb_best_map
| Xcb_types.Rgb_blue_map        -> WindowProperties.rgb_blue_map
| Xcb_types.Rgb_default_map     -> WindowProperties.rgb_default_map
| Xcb_types.Rgb_gray_map        -> WindowProperties.rgb_gray_map
| Xcb_types.Rgb_green_map       -> WindowProperties.rgb_green_map
| Xcb_types.Rgb_red_map         -> WindowProperties.rgb_red_map
| Xcb_types.String              -> WindowProperties.string
| Xcb_types.Visualid            -> WindowProperties.visualid
| Xcb_types.Window              -> WindowProperties.window
| Xcb_types.Wm_command          -> WindowProperties.wm_command
| Xcb_types.Wm_hints            -> WindowProperties.wm_hints
| Xcb_types.Wm_client_machine   -> WindowProperties.wm_client_machine
| Xcb_types.Wm_icon_name        -> WindowProperties.wm_icon_name
| Xcb_types.Wm_icon_size        -> WindowProperties.wm_icon_size
| Xcb_types.Wm_name             -> WindowProperties.wm_name
| Xcb_types.Wm_normal_hints     -> WindowProperties.wm_normal_hints
| Xcb_types.Wm_size_hints       -> WindowProperties.wm_size_hints
| Xcb_types.Wm_zoom_hints       -> WindowProperties.wm_zoom_hints
| Xcb_types.Min_space           -> WindowProperties.min_space
| Xcb_types.Norm_space          -> WindowProperties.norm_space
| Xcb_types.Max_space           -> WindowProperties.max_space
| Xcb_types.End_space           -> WindowProperties.end_space
| Xcb_types.Superscript_x       -> WindowProperties.superscript_x
| Xcb_types.Superscript_y       -> WindowProperties.superscript_y
| Xcb_types.Subscript_x         -> WindowProperties.subscript_x
| Xcb_types.Subscript_y         -> WindowProperties.subscript_y
| Xcb_types.Underline_position  -> WindowProperties.underline_position
| Xcb_types.Underline_thickness -> WindowProperties.underline_thickness
| Xcb_types.Strikeout_ascent    -> WindowProperties.strikeout_ascent
| Xcb_types.Strikeout_descent   -> WindowProperties.strikeout_descent
| Xcb_types.Italic_angle        -> WindowProperties.italic_angle
| Xcb_types.X_height            -> WindowProperties.x_height
| Xcb_types.Quad_width          -> WindowProperties.quad_width
| Xcb_types.Weight              -> WindowProperties.weight
| Xcb_types.Point_size          -> WindowProperties.point_size
| Xcb_types.Resolution          -> WindowProperties.resolution
| Xcb_types.Copyright           -> WindowProperties.copyright
| Xcb_types.Notice              -> WindowProperties.notice
| Xcb_types.Font_name           -> WindowProperties.font_name
| Xcb_types.Family_name         -> WindowProperties.family_name
| Xcb_types.Full_name           -> WindowProperties.full_name
| Xcb_types.Cap_height          -> WindowProperties.cap_height
| Xcb_types.Wm_class            -> WindowProperties.wm_class
| Xcb_types.Wm_transient_for    -> WindowProperties.wm_transient_for

let change_property_string (conn, _) wid mode atom value = begin

  let mode_v = mode_to_c mode
  and atom_v = atom_code atom
  and length = String.length value in

  let c = _change_property_str conn mode_v wid atom_v WindowProperties.string 8 length value in
  fun () -> match _request_check conn c with
    | None -> true
    | Some x ->
        Printf.printf "error_code : %d\n" (!@(x |-> code));
        false

end
