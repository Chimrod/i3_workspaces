let c_headers = "#include <time.h>\n#include <xcb/xcb.h>"

let main () =
  let stubs_out = open_out "bindings_stubs_gen.c" in
  let stubs_fmt = Format.formatter_of_out_channel stubs_out in
  Format.fprintf stubs_fmt "%s@\n" c_headers;
  Cstubs.Types.write_c stubs_fmt (module Bindings.Types);
  Format.pp_print_flush stubs_fmt ();
  close_out stubs_out

let () = main ()
