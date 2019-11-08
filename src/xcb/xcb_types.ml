type color = int

type xcb_event_mask =
| No_event
| Key_press
| Key_release
| Button_press
| Button_release
| Enter_window
| Leave_window
| Pointer_motion
| Pointer_motion_hint
| Button_1_motion
| Button_2_motion
| Button_3_motion
| Button_4_motion
| Button_5_motion
| Button_motion
| Keymap_state
| Exposure
| Visibility_change
| Structure_notify
| Resize_redirect
| Substructure_notify
| Substructure_redirect
| Focus_change
| Property_change
| Color_map_change
| Owner_grab_button

type xcb_cw =
| Back_pixmap       of int
| Back_pixel        of color
| Border_pixmap     of int
| Border_pixel      of int
| Bit_gravity       of int
| Win_gravity       of int
| Backing_store     of int
| Backing_planes    of int
| Backing_pixel     of int
| Override_redirect of int
| Save_under        of int
| Event_mask        of xcb_event_mask list
| Dont_propagate    of int
| Colormap          of int
| Cursor            of int


(** Change mode *)

type modes =
| Replace
| Prepend
| Append

type atoms =
| None
| Any
| Primary
| Secondary
| Arc
| Atom
| Bitmap
| Cardinal
| Colormap
| Cursor
| Cut_buffer0
| Cut_buffer1
| Cut_buffer2
| Cut_buffer3
| Cut_buffer4
| Cut_buffer5
| Cut_buffer6
| Cut_buffer7
| Drawable
| Font
| Integer
| Pixmap
| Point
| Rectangle
| Resource_manager
| Rgb_color_map
| Rgb_best_map
| Rgb_blue_map
| Rgb_default_map
| Rgb_gray_map
| Rgb_green_map
| Rgb_red_map
| String
| Visualid
| Window
| Wm_command
| Wm_hints
| Wm_client_machine
| Wm_icon_name
| Wm_icon_size
| Wm_name
| Wm_normal_hints
| Wm_size_hints
| Wm_zoom_hints
| Min_space
| Norm_space
| Max_space
| End_space
| Superscript_x
| Superscript_y
| Subscript_x
| Subscript_y
| Underline_position
| Underline_thickness
| Strikeout_ascent
| Strikeout_descent
| Italic_angle
| X_height
| Quad_width
| Weight
| Point_size
| Resolution
| Copyright
| Notice
| Font_name
| Family_name
| Full_name
| Cap_height
| Wm_class
| Wm_transient_for
