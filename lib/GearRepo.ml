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

let update_soft_gear_status id status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE soft_gear SET status = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
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

let add_nfa_item (item : Gear.nfa_item) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO nfa_items (id, name, nfa_type, manufacturer, serial_number, tax_stamp_id,
        caliber_bore, purchase_date, form_type, trust_name, notes, status, rounds_fired,
        clean_interval_rounds, oil_interval_days, needs_maintenance, maintenance_conditions,
        created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT item.nfa_id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT item.nfa_name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT item.nfa_type) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT (Option.value item.manufacturer ~default:"")) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value item.serial_number ~default:"")) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT item.tax_stamp_id) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.TEXT (Option.value item.caliber_bore ~default:"")) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.INT item.nfa_purchase_date) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value item.form_type ~default:"")) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT (Option.value item.trust_name ~default:"")) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT (Option.value item.nfa_notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.TEXT item.nfa_status) |> ignore;
    Sqlite3.bind stmt 13 (Sqlite3.Data.INT (Int64.of_int item.rounds_fired)) |> ignore;
    Sqlite3.bind stmt 14 (Sqlite3.Data.INT (Int64.of_int item.clean_interval_rounds)) |> ignore;
    Sqlite3.bind stmt 15 (Sqlite3.Data.INT (Int64.of_int item.oil_interval_days)) |> ignore;
    Sqlite3.bind stmt 16 (Sqlite3.Data.INT (if item.needs_maintenance then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 17 (Sqlite3.Data.TEXT (Option.value item.maintenance_conditions ~default:"")) |> ignore;
    Sqlite3.bind stmt 18 (Sqlite3.Data.INT item.nfa_created_at) |> ignore;
    Sqlite3.bind stmt 19 (Sqlite3.Data.INT item.nfa_updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_nfa_items () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM nfa_items ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
          let item : Gear.nfa_item = {
            Gear.nfa_id = Id.of_int64 (Int64.of_int (get_int 0));
            Gear.nfa_name = get_string 1;
            Gear.nfa_type = get_string 2;
            Gear.manufacturer = get_opt_string 3;
            Gear.serial_number = get_opt_string 4;
            Gear.tax_stamp_id = get_string 5;
            Gear.caliber_bore = get_opt_string 6;
            Gear.nfa_purchase_date = Id.of_int64 (Int64.of_int (get_int 7));
            Gear.form_type = get_opt_string 8;
            Gear.trust_name = get_opt_string 9;
            Gear.nfa_notes = get_opt_string 10;
            Gear.nfa_status = get_string 11;
            Gear.rounds_fired = get_int 12;
            Gear.clean_interval_rounds = get_int 13;
            Gear.oil_interval_days = get_int 14;
            Gear.needs_maintenance = (get_int 15 = 1);
            Gear.maintenance_conditions = get_opt_string 16;
            Gear.last_cleaned_at = get_opt_int 17;
            Gear.last_oiled_at = get_opt_int 18;
            Gear.nfa_created_at = Id.of_int64 (Int64.of_int (get_int 19));
            Gear.nfa_updated_at = Id.of_int64 (Int64.of_int (get_int 20));
          } in
          collect (item :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_nfa_item_by_id id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM nfa_items WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
          let item : Gear.nfa_item = {
            Gear.nfa_id = Id.of_int64 (Int64.of_int (get_int 0));
            Gear.nfa_name = get_string 1;
            Gear.nfa_type = get_string 2;
            Gear.manufacturer = get_opt_string 3;
            Gear.serial_number = get_opt_string 4;
            Gear.tax_stamp_id = get_string 5;
            Gear.caliber_bore = get_opt_string 6;
            Gear.nfa_purchase_date = Id.of_int64 (Int64.of_int (get_int 7));
            Gear.form_type = get_opt_string 8;
            Gear.trust_name = get_opt_string 9;
            Gear.nfa_notes = get_opt_string 10;
            Gear.nfa_status = get_string 11;
            Gear.rounds_fired = get_int 12;
            Gear.clean_interval_rounds = get_int 13;
            Gear.oil_interval_days = get_int 14;
            Gear.needs_maintenance = (get_int 15 = 1);
            Gear.maintenance_conditions = get_opt_string 16;
            Gear.last_cleaned_at = get_opt_int 17;
            Gear.last_oiled_at = get_opt_int 18;
            Gear.nfa_created_at = Id.of_int64 (Int64.of_int (get_int 19));
            Gear.nfa_updated_at = Id.of_int64 (Int64.of_int (get_int 20));
          } in
          Some item
      | _ -> None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    match result with
    | Some item -> Ok item
    | None -> Error (Error.repository_not_found "nfa_item" id)
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_nfa_item_rounds_fired id rounds =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE nfa_items SET rounds_fired = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int rounds)) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_nfa_item id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM nfa_items WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_attachment (att : Gear.attachment) =
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

let get_all_attachments () =
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

let get_attachments_for_firearm firearm_id =
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
