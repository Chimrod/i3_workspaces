type t = Inifiles.inifile

(** Load a value from the global section *)
let load_global conf field = begin
  try Some(conf#getval "global" field) with
  | Inifiles.Invalid_section _ -> None
  | Inifiles.Invalid_element _-> None
end

(** Load the value from the Configuration
  If the key does not exist, look for the global section
*)
let load_value conf section field = begin

  try Some (conf#getval section field) with
  | Inifiles.Invalid_element _ ->
    load_global conf field
  | Inifiles.Invalid_section _ ->
    Printf.printf "\tUnknown workspace %s\n%!" section;
    load_global conf field
end

(** Regex for extracting the variables parameters in configuration file *)
let param = Str.regexp {|\${.+}|}

(** Replace the given string with the values associated with key in the ini file *)
let rec get_params t section str = begin

  match Str.search_forward param str 0 with
  | exception Not_found -> Some str
  | _ ->
    let matched = Str.matched_string str in
    let len = String.length matched in
    (* Remove the ${ } around the text *)
    let argument = String.sub matched 2 (len - 3) in
    begin match load_value t section argument with
    | None ->
        (* This should occur only in startup *)
        Printf.eprintf "Key %s not found in section [%s] nor [global]\n%!" argument section;
        None
    | Some x ->
        get_params t section (Str.replace_first param x str)
    end;

end

(** Check the whole configuration to ensure that each variable use in a
    section is defined somewhere *)
let check_section conf section = begin
  let f _key value = begin match get_params conf section value with
  | None -> raise Not_found
  | Some _ -> ()
  end in
  conf#iter f section
end

let load f = begin
  let conf = new Inifiles.inifile f in
  let sections = conf#sects in
  (* Ensure we have a global section *)
  match List.exists ((=) "global") sections with
  | false ->
      Printf.eprintf "No [global] section found in %s\nExciting\n%!" f;
      None
  | true ->
      match List.iter (check_section conf) sections with
      | exception Not_found -> None
      | _ -> Some conf
end
