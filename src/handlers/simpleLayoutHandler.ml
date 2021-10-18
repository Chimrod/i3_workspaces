include Common
include DefaultHandler.M

let (|>>=?) opt f = Option.bind ~f opt

(** Check if we should manage this workspace *)
let handlers ini name =
Configuration.load_value ini name "layout"
|>>=? fun layout -> match layout with
| "horizontal" -> Some I3ipc.Reply.SplitH
| "vertical" -> Some I3ipc.Reply.SplitV
| _ -> None

let workspace_init ini node name state =
    (* Set the workspace in vertical mode *)
    match handlers ini name with
    | None -> state
    | Some t -> Actions.split node t state
