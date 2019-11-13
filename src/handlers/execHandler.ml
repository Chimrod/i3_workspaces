include Common
include DefaultHandler

type t = Configuration.t

let workspace_focus ini ~workspace:_ name state = begin
  Configuration.load_values ini name "on_focus"
  |> List.fold_left (Actions.launch `NoStartupId) state
  |> Lwt.return
end

let workspace_init ini ~workspace:_ name state = begin
  (* If there is a swallow option, we run it in first *)
  let state = Configuration.load_values ini name "on_init_swallow_class"
  |> List.fold_left (fun a b -> Actions.swallow b a) state
  in
  (* Do not run no-startup-id : we want the application to be launched on
     this workspace *)
     Configuration.load_values ini name "on_init"
  |> List.fold_left (Actions.launch `StartupId) state
  |> Lwt.return
end
