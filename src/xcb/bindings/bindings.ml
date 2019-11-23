module Types = functor (S : Cstubs.Types.TYPE) -> struct
  open S

  type 'a structure = 'a Ctypes.structure

  module Tm = struct
    type tm
    type t = tm structure
    let t : t typ = structure "tm"
    let tm_hour = (field t "tm_hour" int)
    let tm_year = (field t "tm_year" int)

    let () = seal t
  end

  let uint8_v  = Unsigned.UInt8.( view ~read:to_int ~write:of_int (uint8_t))
  let uint16_v = Unsigned.UInt16.(view ~read:to_int ~write:of_int (uint16_t))
  let uint32_v = Unsigned.UInt32.(view ~read:to_int ~write:of_int (uint32_t))

  type c_connexion = unit Ctypes.ptr
  let c_connexion: c_connexion typ = ptr void

  type visualid_t = int
  let visualid_t: visualid_t typ = uint32_v

  type xcb_atom_t = Unsigned.uint32
  let xcb_atom_t: xcb_atom_t typ = uint32_t

  let id = uint32_t
  type xcb_colormap_t = int
  let xcb_colormap_t: xcb_colormap_t typ = uint32_v

  let copy_from_parent = (constant "XCB_COPY_FROM_PARENT"         int)

  type screen_t
   let screen: screen_t structure typ = structure "xcb_screen_t"
   let root                    = field screen "root"                  id
   let xcb_colormap            = field screen "default_colormap"      xcb_colormap_t
   let white_pixel             = field screen "white_pixel"           uint32_v
   let black_pixel             = field screen "black_pixel"           uint32_v
   let current_input_masks     = field screen "current_input_masks"   uint32_v
   let width_in_pixels         = field screen "width_in_pixels"       uint16_v
   let height_in_pixels        = field screen "height_in_pixels"      uint16_v
   let width_in_mm             = field screen "width_in_millimeters"  uint16_v
   let height_in_mm            = field screen "height_in_millimeters" uint16_v
   let min_installed_maps      = field screen "min_installed_maps"    uint16_v
   let max_installed_maps      = field screen "max_installed_maps"    uint16_v
   let root_visual             = field screen "root_visual"           visualid_t
   let backing_stores          = field screen "backing_stores"        uint8_v
   let save_unders             = field screen "save_unders"           uint8_v
   let root_depth              = field screen "root_depth"            uint8_v
   let allowed_depths_len      = field screen "allowed_depths_len"    uint8_v
  let () = seal screen

  type setup_t
   let setup_t: setup_t structure typ = structure "xcb_setup_t"
   let status = field setup_t "status" uint8_t
   let s_pad0 = field setup_t "pad0" uint8_t
   let roots_len = field setup_t "roots_len" uint8_t
  let () = seal setup_t


  type screen_iterator
   let screen_iterator: screen_iterator structure typ = structure "xcb_screen_iterator_t"
   let data  = field screen_iterator "data"  (ptr screen)
   let rem   = field screen_iterator "rem"   int
   let index = field screen_iterator "index" int
  let () = seal screen_iterator

  type generic_error
   let generic_error: generic_error structure typ = structure "xcb_generic_error_t"
   let generic_error = typedef generic_error "xcb_generic_error_t"

   let _type = field generic_error "response_type" uint8_v
   let code = field generic_error "error_code" uint8_v
  let () = seal generic_error

  type generic_event_t
   let generic_event_t: generic_event_t structure typ = structure "xcb_generic_event_t"
   let generic_event_t= typedef generic_event_t "xcb_generic_event_t"
   let response_type            = field generic_event_t "response_type"    uint8_v
   let generic_pad0             = field generic_event_t "pad0"             uint8_v
   let sequence                 = field generic_event_t "sequence"         uint16_v
   let pad                      = field generic_event_t "pad"              uint32_t
   let full_sequence            = field generic_event_t "full_sequence"    uint32_t
  let () = seal generic_event_t

  type expose_event_t
   let expose_event_t: expose_event_t structure typ = structure "xcb_expose_event_t"
   let expose_response_type     = field expose_event_t "response_type"     uint8_v
   let expose_pad0              = field expose_event_t "pad0"      uint8_v
   let expose_sequence          = field expose_event_t "sequence"  uint16_v
   let expose_window            = field expose_event_t "window"    id
   let expose_x                 = field expose_event_t "x"         uint16_v
   let expose_y                 = field expose_event_t "y"         uint16_v
   let expose_width             = field expose_event_t "width"     uint16_v
   let expose_height            = field expose_event_t "height"    uint16_v
   let expose_count             = field expose_event_t "count"     uint16_v
  let () = seal expose_event_t

  type input_event_t
   let input_event_t: expose_event_t structure typ = structure "xcb_key_press_event_t"
   let input_response_type      = field input_event_t "response_type"       uint8_v
   let input_detail             = field input_event_t "detail"      uint8_v
   let input_sequence           = field input_event_t "sequence"    uint16_v
   let input_time               = field input_event_t "time"        Tm.t
   let input_root               = field input_event_t "root"        id
   let input_event              = field input_event_t "event"       id
   let input_child              = field input_event_t "child"       id
   let input_root_x             = field input_event_t "root_x"      uint16_v
   let input_root_y             = field input_event_t "root_y"      uint16_v
   let input_event_x            = field input_event_t "event_x"     uint16_v
   let input_event_y            = field input_event_t "event_y"     uint16_v
   let input_state              = field input_event_t "state"       uint16_v
   let input_same_screen        = field input_event_t "same_screen" uint8_v
  let () = seal input_event_t

  type destroy_notify_event_t
   let destroy_notify_event_t: destroy_notify_event_t structure typ = structure "xcb_destroy_notify_event_t"
   let destroy_response_type    = field destroy_notify_event_t "response_type"  uint8_v
   let destroy_pad0             = field destroy_notify_event_t "pad0"       uint8_v
   let destroy_sequence         = field destroy_notify_event_t "sequence"   uint16_v
   let destroy_event            = field destroy_notify_event_t "event"      id
   let _destroy_window          = field destroy_notify_event_t "window"     id
  let () = seal destroy_notify_event_t

  module WindowProperties = struct
    let cw_back_pixmap             = (constant "XCB_CW_BACK_PIXMAP"         int)
    let cw_back_pixel              = (constant "XCB_CW_BACK_PIXEL"          int)
    let cw_border_pixmap           = (constant "XCB_CW_BORDER_PIXMAP"       int)
    let cw_border_pixel            = (constant "XCB_CW_BORDER_PIXEL"        int)
    let cw_bit_gravity             = (constant "XCB_CW_BIT_GRAVITY"         int)
    let cw_win_gravity             = (constant "XCB_CW_WIN_GRAVITY"         int)
    let cw_backing_store           = (constant "XCB_CW_BACKING_STORE"       int)
    let cw_backing_planes          = (constant "XCB_CW_BACKING_PLANES"      int)
    let cw_backing_pixel           = (constant "XCB_CW_BACKING_PIXEL"       int)
    let cw_override_redirect       = (constant "XCB_CW_OVERRIDE_REDIRECT"   int)
    let cw_save_under              = (constant "XCB_CW_SAVE_UNDER"          int)
    let cw_event_mask              = (constant "XCB_CW_EVENT_MASK"          int)
    let cw_dont_propagate          = (constant "XCB_CW_DONT_PROPAGATE"      int)
    let cw_colormap                = (constant "XCB_CW_COLORMAP"            int)
    let cw_cursor                  = (constant "XCB_CW_CURSOR"              int)


    (* Change mode *)
    let replace = (constant "XCB_PROP_MODE_REPLACE"                         int)
    let prepend = (constant "XCB_PROP_MODE_PREPEND"                         int)
    let append  = (constant "XCB_PROP_MODE_APPEND"                          int)

    let none                  = (constant "XCB_ATOM_NONE"           uint32_t)
    let any                   = (constant "XCB_ATOM_ANY"            uint32_t)
    let primary               = (constant "XCB_ATOM_PRIMARY"        uint32_t)
    let secondary             = (constant "XCB_ATOM_SECONDARY"      uint32_t)
    let arc                   = (constant "XCB_ATOM_ARC"            uint32_t)
    let atom                  = (constant "XCB_ATOM_ATOM"           uint32_t)
    let bitmap                = (constant "XCB_ATOM_BITMAP"         uint32_t)
    let cardinal              = (constant "XCB_ATOM_CARDINAL"       uint32_t)
    let colormap              = (constant "XCB_ATOM_COLORMAP"       uint32_t)
    let cursor                = (constant "XCB_ATOM_CURSOR"         uint32_t)
    let cut_buffer0           = (constant "XCB_ATOM_CUT_BUFFER0"    uint32_t)
    let cut_buffer1           = (constant "XCB_ATOM_CUT_BUFFER1"    uint32_t)
    let cut_buffer2           = (constant "XCB_ATOM_CUT_BUFFER2"    uint32_t)
    let cut_buffer3           = (constant "XCB_ATOM_CUT_BUFFER3"    uint32_t)
    let cut_buffer4           = (constant "XCB_ATOM_CUT_BUFFER4"    uint32_t)
    let cut_buffer5           = (constant "XCB_ATOM_CUT_BUFFER5"    uint32_t)
    let cut_buffer6           = (constant "XCB_ATOM_CUT_BUFFER6"    uint32_t)
    let cut_buffer7           = (constant "XCB_ATOM_CUT_BUFFER7"    uint32_t)
    let drawable              = (constant "XCB_ATOM_DRAWABLE"       uint32_t)
    let font                  = (constant "XCB_ATOM_FONT"           uint32_t)
    let integer               = (constant "XCB_ATOM_INTEGER"       uint32_t)
    let pixmap                = (constant "XCB_ATOM_PIXMAP"         uint32_t)
    let point                 = (constant "XCB_ATOM_POINT"          uint32_t)
    let rectangle             = (constant "XCB_ATOM_RECTANGLE"      uint32_t)
    let resource_manager      = (constant "XCB_ATOM_RESOURCE_MANAGER"   uint32_t)
    let rgb_color_map         = (constant "XCB_ATOM_RGB_COLOR_MAP"  uint32_t)
    let rgb_best_map          = (constant "XCB_ATOM_RGB_BEST_MAP"   uint32_t)
    let rgb_blue_map          = (constant "XCB_ATOM_RGB_BLUE_MAP"   uint32_t)
    let rgb_default_map       = (constant "XCB_ATOM_RGB_DEFAULT_MAP"    uint32_t)
    let rgb_gray_map          = (constant "XCB_ATOM_RGB_GRAY_MAP"   uint32_t)
    let rgb_green_map         = (constant "XCB_ATOM_RGB_GREEN_MAP"  uint32_t)
    let rgb_red_map           = (constant "XCB_ATOM_RGB_RED_MAP"    uint32_t)
    let string                = (constant "XCB_ATOM_STRING"         uint32_t)
    let visualid              = (constant "XCB_ATOM_VISUALID"       uint32_t)
    let window                = (constant "XCB_ATOM_WINDOW"         uint32_t)
    let wm_command            = (constant "XCB_ATOM_WM_COMMAND"     uint32_t)
    let wm_hints              = (constant "XCB_ATOM_WM_HINTS"       uint32_t)
    let wm_client_machine     = (constant "XCB_ATOM_WM_CLIENT_MACHINE"  uint32_t)
    let wm_icon_name          = (constant "XCB_ATOM_WM_ICON_NAME"   uint32_t)
    let wm_icon_size          = (constant "XCB_ATOM_WM_ICON_SIZE"   uint32_t)
    let wm_name               = (constant "XCB_ATOM_WM_NAME"        uint32_t)
    let wm_normal_hints       = (constant "XCB_ATOM_WM_NORMAL_HINTS"    uint32_t)
    let wm_size_hints         = (constant "XCB_ATOM_WM_SIZE_HINTS"  uint32_t)
    let wm_zoom_hints         = (constant "XCB_ATOM_WM_ZOOM_HINTS"  uint32_t)
    let min_space             = (constant "XCB_ATOM_MIN_SPACE"      uint32_t)
    let norm_space            = (constant "XCB_ATOM_NORM_SPACE"     uint32_t)
    let max_space             = (constant "XCB_ATOM_MAX_SPACE"      uint32_t)
    let end_space             = (constant "XCB_ATOM_END_SPACE"      uint32_t)
    let superscript_x         = (constant "XCB_ATOM_SUPERSCRIPT_X"  uint32_t)
    let superscript_y         = (constant "XCB_ATOM_SUPERSCRIPT_Y"  uint32_t)
    let subscript_x           = (constant "XCB_ATOM_SUBSCRIPT_X"    uint32_t)
    let subscript_y           = (constant "XCB_ATOM_SUBSCRIPT_Y"    uint32_t)
    let underline_position    = (constant "XCB_ATOM_UNDERLINE_POSITION" uint32_t)
    let underline_thickness   = (constant "XCB_ATOM_UNDERLINE_THICKNESS" uint32_t)
    let strikeout_ascent      = (constant "XCB_ATOM_STRIKEOUT_ASCENT"   uint32_t)
    let strikeout_descent     = (constant "XCB_ATOM_STRIKEOUT_DESCENT"  uint32_t)
    let italic_angle          = (constant "XCB_ATOM_ITALIC_ANGLE"   uint32_t)
    let x_height              = (constant "XCB_ATOM_X_HEIGHT"       uint32_t)
    let quad_width            = (constant "XCB_ATOM_QUAD_WIDTH"     uint32_t)
    let weight                = (constant "XCB_ATOM_WEIGHT"         uint32_t)
    let point_size            = (constant "XCB_ATOM_POINT_SIZE"     uint32_t)
    let resolution            = (constant "XCB_ATOM_RESOLUTION"     uint32_t)
    let copyright             = (constant "XCB_ATOM_COPYRIGHT"      uint32_t)
    let notice                = (constant "XCB_ATOM_NOTICE"         uint32_t)
    let font_name             = (constant "XCB_ATOM_FONT_NAME"      uint32_t)
    let family_name           = (constant "XCB_ATOM_FAMILY_NAME"    uint32_t)
    let full_name             = (constant "XCB_ATOM_FULL_NAME"      uint32_t)
    let cap_height            = (constant "XCB_ATOM_CAP_HEIGHT"     uint32_t)
    let wm_class              = (constant "XCB_ATOM_WM_CLASS"       uint32_t)
    let wm_transient_for      = (constant "XCB_ATOM_WM_TRANSIENT_FOR"   uint32_t)

  end

  module Events = struct

    (** Event masks *)

   let mask_no_event            = (constant "XCB_EVENT_MASK_NO_EVENT"       int)
   let mask_key_press           = (constant "XCB_EVENT_MASK_KEY_PRESS"      int)
   let mask_key_release         = (constant "XCB_EVENT_MASK_KEY_RELEASE"    int)
   let mask_button_press        = (constant "XCB_EVENT_MASK_BUTTON_PRESS"   int)
   let mask_button_release      = (constant "XCB_EVENT_MASK_BUTTON_RELEASE" int)
   let mask_enter_window        = (constant "XCB_EVENT_MASK_ENTER_WINDOW"   int)
   let mask_leave_window        = (constant "XCB_EVENT_MASK_LEAVE_WINDOW"   int)
   let mask_pointer_motion      = (constant "XCB_EVENT_MASK_POINTER_MOTION" int)
   let mask_pointer_motion_hint = (constant "XCB_EVENT_MASK_POINTER_MOTION_HINT" int)
   let mask_button_1_motion     = (constant "XCB_EVENT_MASK_BUTTON_1_MOTION" int)
   let mask_button_2_motion     = (constant "XCB_EVENT_MASK_BUTTON_2_MOTION" int)
   let mask_button_3_motion     = (constant "XCB_EVENT_MASK_BUTTON_3_MOTION" int)
   let mask_button_4_motion     = (constant "XCB_EVENT_MASK_BUTTON_4_MOTION" int)
   let mask_button_5_motion     = (constant "XCB_EVENT_MASK_BUTTON_5_MOTION" int)
   let mask_button_motion       = (constant "XCB_EVENT_MASK_BUTTON_MOTION"  int)
   let mask_keymap_state        = (constant "XCB_EVENT_MASK_KEYMAP_STATE"   int)
   let mask_exposure            = (constant "XCB_EVENT_MASK_EXPOSURE"       int)
   let mask_visibility_change   = (constant "XCB_EVENT_MASK_VISIBILITY_CHANGE" int)
   let mask_structure_notify    = (constant "XCB_EVENT_MASK_STRUCTURE_NOTIFY" int)
   let mask_resize_redirect     = (constant "XCB_EVENT_MASK_RESIZE_REDIRECT" int)
   let mask_substructure_notify = (constant "XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY" int)
   let mask_substructure_redirect = (constant "XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT" int)
   let mask_focus_change        = (constant "XCB_EVENT_MASK_FOCUS_CHANGE"   int)
   let mask_property_change     = (constant "XCB_EVENT_MASK_PROPERTY_CHANGE" int)
   let mask_color_map_change    = (constant "XCB_EVENT_MASK_COLOR_MAP_CHANGE" int)
   let mask_owner_grab_button   = (constant "XCB_EVENT_MASK_OWNER_GRAB_BUTTON" int)

   (** Event types *)

   let key_press                = (constant "XCB_KEY_PRESS"         short)
   let key_release              = (constant "XCB_KEY_RELEASE"       short)
   let button_press             = (constant "XCB_BUTTON_PRESS"      short)
   let button_release           = (constant "XCB_BUTTON_RELEASE"    short)
   let motion_notify            = (constant "XCB_MOTION_NOTIFY"     short)
   let enter_notify             = (constant "XCB_ENTER_NOTIFY"      short)
   let leave_notify             = (constant "XCB_LEAVE_NOTIFY"      short)
   let focus_in                 = (constant "XCB_FOCUS_IN"          short)
   let focus_out                = (constant "XCB_FOCUS_OUT"         short)
   let keymap_notify            = (constant "XCB_KEYMAP_NOTIFY"     short)
   let expose                   = (constant "XCB_EXPOSE"            short)
   let graphics_exposure        = (constant "XCB_GRAPHICS_EXPOSURE" short)
   let no_exposure              = (constant "XCB_NO_EXPOSURE"       short)
   let visibility_notify        = (constant "XCB_VISIBILITY_NOTIFY" short)
   let create_notify            = (constant "XCB_CREATE_NOTIFY"     short)
   let destroy_notify           = (constant "XCB_DESTROY_NOTIFY"    short)
   let unmap_notify             = (constant "XCB_UNMAP_NOTIFY"      short)
   let map_notify               = (constant "XCB_MAP_NOTIFY"        short)
   let map_request              = (constant "XCB_MAP_REQUEST"       short)
   let reparent_notify          = (constant "XCB_REPARENT_NOTIFY"   short)
   let configure_notify         = (constant "XCB_CONFIGURE_NOTIFY"  short)
   let gravity_notify           = (constant "XCB_GRAVITY_NOTIFY"    short)
   let circulate_notify         = (constant "XCB_CIRCULATE_NOTIFY"  short)

  end

  module Requests = struct
    let configure_request       = (constant "XCB_CONFIGURE_REQUEST" short)
    let resize_request          = (constant "XCB_RESIZE_REQUEST"    short)
  end
end
