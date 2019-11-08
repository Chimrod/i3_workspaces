
type connexion

(** Retrieve the result after a request to the X server. 

  After each request, the result is delayed and can be checked later. You can
  discard the cookie you are not interested by the result. *)
type 'a cookie = unit -> 'a

(** Connect to the X server *)
val connect: ?display:string -> ?screen:int -> unit -> connexion option

type visualid_t

type id

val int_of_id: id -> int

(* Screen definition *)
type screen = {
  root: id;
  white_pixel:Xcb_types.color;
  black_pixel:Xcb_types.color;
  width_in_pixels: int;
  height_in_pixels: int;
  root_visual: visualid_t;
  root_depth: int;
}

(** Load all the declared screens *)
val get_screens: connexion -> screen list


val create_window:
  connexion ->
  depth:int ->
  parent:id ->
  x:int ->
  y:int -> 
  width:int ->
  height:int ->
  border:int -> 
  int ->
  visual:visualid_t->
  Xcb_types.xcb_cw list ->
  id option cookie

val destroy_window:
  connexion ->
  id ->
  bool cookie

val map_window:
  connexion ->
  id ->
  bool cookie

val flush:
  connexion -> int

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

val poll_event: connexion -> event_result Lwt.t

val change_property_string: 
  connexion -> 
  id -> Xcb_types.modes -> 
  Xcb_types.atoms -> 
  string -> 
  bool cookie
