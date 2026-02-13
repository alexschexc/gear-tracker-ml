(* gearTracker_ml - Attachment Repository *)

let add (att : Gear.attachment) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO attachments (id, name, category, brand, model, serial_number, purchase_date,
        mounted_on_firearm_id, mount_position, zero_distance_yards, zero_notes, notes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT att.att_id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT att.att_name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT att.att_category) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT (Option.value att.brand ~default:"")) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value att.model ~default:"")) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT (Option.value att.serial_number ~default:"")) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Option.value att.att_purchase_date ~default:0L)) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.INT (Option.value att.mounted_on_firearm_id ~default:0L)) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value att.mount_position ~default:"")) |> ignore;
    let zero_dist = att.zero_distance_yards |> Option.map Int64.of_int in
    Sqlite3.bind stmt 10 (Sqlite3.Data.INT (Option.value zero_dist ~default:0L)) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT (Option.value att.zero_notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.TEXT (Option.value att.att_notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 13 (Sqlite3.Data.INT att.att_created_at) |> ignore;
    Sqlite3.bind stmt 14 (Sqlite3.Data.INT att.att_updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM attachments ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_int_opt i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let att : Gear.attachment = {
          Gear.att_id = Id.of_int64 (Int64.of_int (get_int 0));
          Gear.att_name = get_string 1;
          Gear.att_category = get_string 2;
          Gear.brand = get_opt_string 3;
          Gear.model = get_opt_string 4;
          Gear.serial_number = get_opt_string 5;
          Gear.att_purchase_date = get_int64_opt 6;
          Gear.mounted_on_firearm_id = get_int64_opt 7;
          Gear.mount_position = get_opt_string 8;
          Gear.zero_distance_yards = get_int_opt 9;
          Gear.zero_notes = get_opt_string 10;
          Gear.att_notes = get_opt_string 11;
          Gear.att_created_at = Id.of_int64 (Int64.of_int (get_int 12));
          Gear.att_updated_at = Id.of_int64 (Int64.of_int (get_int 13));
        } in
        collect (att :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_for_firearm firearm_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM attachments WHERE mounted_on_firearm_id = ? ORDER BY name" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT firearm_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_int_opt i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let att : Gear.attachment = {
          Gear.att_id = Id.of_int64 (Int64.of_int (get_int 0));
          Gear.att_name = get_string 1;
          Gear.att_category = get_string 2;
          Gear.brand = get_opt_string 3;
          Gear.model = get_opt_string 4;
          Gear.serial_number = get_opt_string 5;
          Gear.att_purchase_date = get_int64_opt 6;
          Gear.mounted_on_firearm_id = get_int64_opt 7;
          Gear.mount_position = get_opt_string 8;
          Gear.zero_distance_yards = get_int_opt 9;
          Gear.zero_notes = get_opt_string 10;
          Gear.att_notes = get_opt_string 11;
          Gear.att_created_at = Id.of_int64 (Int64.of_int (get_int 12));
          Gear.att_updated_at = Id.of_int64 (Int64.of_int (get_int 13));
        } in
        collect (att :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_by_id id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM attachments WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64 i = match row i with Sqlite3.Data.INT x -> x | _ -> 0L in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_int64 i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let get_int64_opt = get_opt_int64 in
        let attachment = {
          Gear.att_id = Id.of_int64 (get_int64 0);
          Gear.att_name = get_string 1;
          Gear.att_category = get_string 2;
          Gear.brand = get_opt_string 3;
          Gear.model = get_opt_string 4;
          Gear.serial_number = get_opt_string 5;
          Gear.att_purchase_date = get_int64_opt 6;
          Gear.mounted_on_firearm_id = get_int64_opt 7;
          Gear.mount_position = get_opt_string 8;
          Gear.zero_distance_yards = get_opt_int 9;
          Gear.zero_notes = get_opt_string 10;
          Gear.att_notes = get_opt_string 11;
          Gear.att_created_at = get_int64 12;
          Gear.att_updated_at = get_int64 13;
        } in
        ignore (Sqlite3.finalize stmt);
        Database.close_db conn;
        Ok (Some attachment)
    | Sqlite3.Rc.DONE ->
        ignore (Sqlite3.finalize stmt);
        Database.close_db conn;
        Ok None
    | _ ->
        ignore (Sqlite3.finalize stmt);
        Database.close_db conn;
        Error (Error.repository_database_error "Unexpected database result")
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM attachments WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
