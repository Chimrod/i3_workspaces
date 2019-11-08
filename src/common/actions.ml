type node = I3ipc.Reply.node

type actions =
  | W: (unit -> (string * (unit -> unit Lwt.t)) Lwt.t) -> actions
  | C: string -> actions

type t = actions list

type answer = I3ipc.Reply.command_outcome list

let create = []

(** Create a container which swallow the given class *)
let swallow class_name t = begin

  let f () = begin

    let%lwt (file, channel) = Lwt_io.open_temp_file ~prefix:"i3_workspaces" () in
    let%lwt () = Lwt_io.fprintf channel {|{"swallows": [{"class": "%s"}]}|} class_name
    in

    let command = "append_layout " ^ file
    and after () = Lwt_io.close channel
    in Lwt.return (command, after)
  end in

  W f::t
end

(** Launch an application *)
let launch exec t command = begin
  C (
    begin match exec with
    | `NoStartupId -> ("exec --no-startup-id \"" ^ command ^ "\"")
    | _ -> ("exec \"" ^ command ^ "\"")
    end
  )::t
end

let _focus (container:I3ipc.Reply.node) = begin
  "[con_id=" ^ (container.I3ipc.Reply.id) ^ "] "
end

let split (container:node) new_layout t = begin
  let open I3ipc.Reply in
  let con_id = _focus container in
  C (
    begin match new_layout with
    | SplitV -> (con_id ^ "split vertical")
    | SplitH -> (con_id ^ "split horizontal")
    | _ -> "nop"
    end
  )::t
end

let layout (container:node) new_layout t = begin
  let open I3ipc.Reply in
  let con_id = _focus container in
  C (
    begin match new_layout with
    | SplitV -> (con_id ^ "layout splitv")
    | SplitH -> (con_id ^ "layout splith")
    | _ -> "nop"
    end
  )::t
end

let exec ~focus message t =
  let focus = _focus focus in
  C (focus ^ message)::t

let empty = []

let apply conn t = begin

  let b = Buffer.create 16 in
  let add_elem b elem = begin
    Buffer.add_string b elem;
    Buffer.add_string b ";";
    b
  end in

  let f (buffer, posts) = begin function
  | C c -> Lwt.return (add_elem buffer c, posts)
  | W f -> let%lwt c, p = f () in
    Lwt.return (add_elem buffer c, p::posts)
  end in

  let%lwt command, posts = Lwt_list.fold_left_s f (b, []) t in
  let command' = Buffer.contents command in
  print_endline command';
  let%lwt result = I3ipc.command conn command' in
  let%lwt posts = Lwt_list.iter_p (fun f -> f ()) posts in
  Lwt.return result
end
