type t = Inifiles.inifile


(** Regex for extracting the variables parameters in configuration file *)
let param = Str.regexp {|\${.+}|}

let load_or_global conf section field = begin
  let local_value = try (conf#getaval section field) with
  | Inifiles.Invalid_element _
  | Inifiles.Invalid_section _ -> []
  and global_value = try (conf#getaval "global" field) with
  | Inifiles.Invalid_element _
  | Inifiles.Invalid_section _ -> [] in
  List.append global_value local_value
end

exception Too_many_recursion of string

let rec last_element = function
  | [] -> None
  | elem::[] -> Some elem
  | _::tl -> (last_element[@tailcal]) tl


(** Replace the given string with the values associated with key in the ini
file *)
let rec get_params t level section str = begin

  (** Prevent infinite looping *)
  begin if level > 10 then
    raise (Too_many_recursion section)
  end;

  match Str.search_forward param str 0 with
  | exception Not_found -> str
  | _ ->
    let matched = Str.matched_string str in
    let len = String.length matched in
    (* Remove the ${ } around the text *)
    let argument = String.sub matched 2 (len - 3) in
    begin match last_element (load_or_global t section argument) with
    | None ->
        (* This should occur only in startup *)
        Printf.eprintf "Key %s not found in section [%s] nor [global]\n%!" argument section;
        raise Not_found

    | Some x ->
      (get_params[@tailcall]) t (level + 1) section (Str.replace_first param x str)
    end;

end

(** Load the value from the Configuration
  If the key does not exist, look for the global section
*)
let load_values conf section field = begin
  load_or_global conf section field
  |> List.rev_map (get_params conf 0 section)
end

let load_value conf section field = begin
  let values = load_or_global conf section field
  |> List.rev_map (get_params conf 0 section) in
  match values with
  | [] -> None
  | hd::_ -> Some hd
end


(** Check the whole configuration to ensure that each variable use in a
    section is defined somewhere *)
let check_section conf section = begin
  let f _key value = ignore (get_params conf 0 section value)
  in
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
      (* First check all the values in the config file *)
      match List.iter (check_section conf) sections with
      | exception Not_found -> None
      | exception Too_many_recursion section ->
        Printf.eprintf "Too many recursion in section %s\n%!" section;
        None
      | _ -> Some conf
end
