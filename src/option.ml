let map ~f = function
| None -> None
| Some x -> Some (f x)

let bind ~f = function
| None -> None
| Some x -> f x

