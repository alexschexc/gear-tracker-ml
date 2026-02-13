type t = int64

let now () = Unix.gettimeofday () |> Int64.of_float
let of_float f = Int64.of_float f
let to_float t = Int64.to_float t
let to_string t = Int64.to_string t

let of_iso8601 s =
  try
    let tm = Scanf.sscanf s "%d-%d-%d" (fun y m d ->
      { Unix.tm_sec = 0; tm_min = 0; tm_hour = 0; tm_mday = d; tm_mon = m - 1; tm_year = y - 1900;
        tm_wday = 0; tm_yday = 0; tm_isdst = false }) in
    let (ts, _) = Unix.mktime tm in
    Ok (Int64.of_float ts)
  with _ -> Error `Invalid_format

let to_iso8601 t =
  let open Unix in
  let tm = localtime (to_float t) in
  Printf.sprintf "%04d-%02d-%02d"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday

let diff a b = Int64.sub a b

let add_seconds t seconds =
  Int64.add t (Int64.of_float (float_of_int seconds))

let days_between a b =
  Int64.to_int (Int64.div (Int64.sub b a) 86400L)

let zero = 0L
