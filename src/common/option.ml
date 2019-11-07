let map ~f = function
| None -> None
| Some x -> Some (f x)

let bind ~f = function
| None -> None
| Some x -> f x


let default ~v = function
| None -> v
| Some x -> x

let (or) = function
| None -> (fun opt2 -> opt2)
| Some x as opt1 -> (fun _ -> opt1)
