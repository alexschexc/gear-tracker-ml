type t = int64

let of_int64 x = x
let to_int64 x = x
let of_string s = Int64.of_string s
let to_string x = Int64.to_string x
let compare = Int64.compare
let equal a b = a = b
let zero = 0L
let succ x = Int64.succ x
let generate ?from:(prev = zero) () = succ prev
