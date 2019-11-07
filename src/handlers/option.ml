let bind ~f = function
| None -> None
| Some x -> f x


