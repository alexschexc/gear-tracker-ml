(* gearTracker_ml - Import/Export Module *)

let read_file path =
  let chan = open_in path in
  let rec read_all acc =
    try
      let line = input_line chan in
      read_all (line :: acc)
    with End_of_file ->
      close_in chan;
      List.rev acc
  in
  read_all []

let parse_sectioned_csv path =
  let lines = read_file path in
  let rec parse_sections acc current_section current_rows = function
    | [] ->
        (match current_section with
         | Some sec -> (sec, List.rev current_rows) :: acc
         | None -> acc)
    | line :: rest ->
        let trimmed = String.trim line in
        if String.length trimmed >= 2 && trimmed.[0] = '[' && trimmed.[String.length trimmed - 1] = ']' then
          let section_name = String.sub trimmed 1 (String.length trimmed - 2) in
          let new_acc = match current_section with
            | Some sec -> (sec, List.rev current_rows) :: acc
            | None -> acc
          in
          parse_sections new_acc (Some section_name) [] rest
        else if trimmed <> "" && trimmed.[0] <> ';' then
          let row = String.split_on_char ',' trimmed in
          parse_sections acc current_section (row :: current_rows) rest
        else
          parse_sections acc current_section current_rows rest
  in
  parse_sections [] None [] lines

let get_field ~name row =
  try
    let rec find n = function
      | [] -> None
      | h :: t -> if h = name then Some (List.nth row n) else find (n + 1) t
    in
    find 0 row
  with _ -> None

let get_required_field ~name row =
  match get_field ~name row with
  | Some "" | None -> Error [Printf.sprintf "Field '%s' is required" name]
  | Some v -> Ok v

let get_optional_field ~name row =
  match get_field ~name row with
  | Some "" | None -> None
  | Some v -> Some v

let get_int_field ~name row =
  match get_field ~name row with
  | Some v -> (try Ok (int_of_string v) with _ -> Error [Printf.sprintf "Invalid integer for '%s'" name])
  | None -> Ok 0

let get_float_field ~name row =
  match get_field ~name row with
  | Some v -> (try Ok (float_of_string v) with _ -> Error [Printf.sprintf "Invalid float for '%s'" name])
  | None -> Ok 0.0

let get_bool_field ~name row =
  match get_field ~name row with
  | Some "true" | Some "1" -> Ok true
  | _ -> Ok false

let string_of_timestamp t = Printf.sprintf "%Ld" t
let timestamp_of_string s = try Int64.of_string s with _ -> 0L

type import_error = { section : string; row : int; errors : string list }

let import_complete_csv path =
  let sections = parse_sectioned_csv path in
  Ok sections
