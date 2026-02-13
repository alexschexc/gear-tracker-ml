(* gearTracker_ml - Gear Repository *)

let add_soft_gear (gear : Gear.t) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO soft_gear (id, name, category, brand, purchase_date, notes, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT gear.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT gear.name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT gear.category) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT (Option.value gear.brand ~default:"")) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT gear.purchase_date) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT (Option.value gear.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.TEXT gear.status) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.INT gear.created_at) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.INT gear.updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_soft_gear () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM soft_gear ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> List.rev acc
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> x | _ -> 0L in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let gear : Gear.t = {
            id = get_int 0;
            name = get_string 1;
            category = get_string 2;
            brand = get_opt_string 3;
            purchase_date = get_int 4;
            notes = get_opt_string 5;
            status = get_string 6;
            created_at = get_int 7;
            updated_at = get_int 8;
          } in
          collect (gear :: acc)
      | _ -> failwith "Unexpected database state"
    in
    let result = collect [] in
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_soft_gear id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM soft_gear WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> x | _ -> 0L in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let gear : Gear.t = {
          id = get_int 0;
          name = get_string 1;
          category = get_string 2;
          brand = get_opt_string 3;
          purchase_date = get_int 4;
          notes = get_opt_string 5;
          status = get_string 6;
          created_at = get_int 7;
          updated_at = get_int 8;
        } in
        Database.close_db conn;
        Ok gear
    | _ ->
        Database.close_db conn;
        Error (Error.repository_not_found "Gear" id)
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_soft_gear id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM soft_gear WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_soft_gear (gear : Gear.t) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      UPDATE soft_gear SET name = ?, category = ?, brand = ?, purchase_date = ?,
        notes = ?, status = ?, updated_at = ? WHERE id = ?
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT gear.name) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT gear.category) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT (Option.value gear.brand ~default:"")) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT gear.purchase_date) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value gear.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT gear.status) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.INT gear.id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_attachment id =
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

let update_soft_gear_status id status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE soft_gear SET status = ?, updated_at = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_nfa_status id status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE nfa_items SET nfa_status = ?, updated_at = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_nfa_item (item : Gear.nfa_item) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {sql|
      UPDATE nfa_items SET name = ?, nfa_type = ?, manufacturer = ?, serial_number = ?,
        tax_stamp_id = ?, caliber_bore = ?, purchase_date = ?, form_type = ?, trust_name = ?,
        notes = ?, status = ?, rounds_fired = ?, clean_interval_rounds = ?, oil_interval_days = ?,
        needs_maintenance = ?, maintenance_conditions = ?, last_cleaned_at = ?, last_oiled_at = ?,
        updated_at = ? WHERE id = ?
    |sql} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT item.nfa_name) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT item.nfa_type) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT (Option.value item.manufacturer ~default:"")) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT (Option.value item.serial_number ~default:"")) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT item.tax_stamp_id) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT (Option.value item.caliber_bore ~default:"")) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT item.nfa_purchase_date) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT (Option.value item.form_type ~default:"")) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value item.trust_name ~default:"")) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT (Option.value item.nfa_notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT item.nfa_status) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.INT (Int64.of_int item.rounds_fired)) |> ignore;
    Sqlite3.bind stmt 13 (Sqlite3.Data.INT (Int64.of_int item.clean_interval_rounds)) |> ignore;
    Sqlite3.bind stmt 14 (Sqlite3.Data.INT (Int64.of_int item.oil_interval_days)) |> ignore;
    Sqlite3.bind stmt 15 (Sqlite3.Data.INT (if item.needs_maintenance then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 16 (Sqlite3.Data.TEXT (Option.value item.maintenance_conditions ~default:"")) |> ignore;
    (match item.last_cleaned_at with Some t -> Sqlite3.bind stmt 17 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 17 Sqlite3.Data.NULL) |> ignore;
    (match item.last_oiled_at with Some t -> Sqlite3.bind stmt 18 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 18 Sqlite3.Data.NULL) |> ignore;
    Sqlite3.bind stmt 19 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 20 (Sqlite3.Data.INT item.nfa_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_attachment_firearm att_id firearm_id_opt =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE attachments SET mounted_on_firearm_id = ?, updated_at = ? WHERE id = ?" in
    (match firearm_id_opt with Some id -> Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) | None -> Sqlite3.bind stmt 1 Sqlite3.Data.NULL) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT att_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let clear_nfa_maintenance_flag id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE nfa_items SET needs_maintenance = 0, updated_at = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
