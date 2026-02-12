(* gearTracker_ml - Firearm Repository *)

let add (firearm : Firearm.t) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {sql|
      INSERT INTO firearms (
        id, name, caliber, serial_number, purchase_date, notes,
        status, is_nfa, nfa_type, tax_stamp_id, form_type, barrel_length,
        trust_name, transfer_status, rounds_fired, clean_interval_rounds,
        oil_interval_days, needs_maintenance, maintenance_conditions,
        last_cleaned_at, last_oiled_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |sql} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT firearm.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT firearm.name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT firearm.caliber) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT firearm.serial_number) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT firearm.purchase_date) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT (Option.value firearm.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.TEXT firearm.status) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.INT (if firearm.is_nfa then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value firearm.nfa_type ~default:"")) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT firearm.tax_stamp_id) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT firearm.form_type) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.TEXT firearm.barrel_length) |> ignore;
    Sqlite3.bind stmt 13 (Sqlite3.Data.TEXT firearm.trust_name) |> ignore;
    Sqlite3.bind stmt 14 (Sqlite3.Data.TEXT firearm.transfer_status) |> ignore;
    Sqlite3.bind stmt 15 (Sqlite3.Data.INT (Int64.of_int firearm.rounds_fired)) |> ignore;
    Sqlite3.bind stmt 16 (Sqlite3.Data.INT (Int64.of_int firearm.clean_interval_rounds)) |> ignore;
    Sqlite3.bind stmt 17 (Sqlite3.Data.INT (Int64.of_int firearm.oil_interval_days)) |> ignore;
    Sqlite3.bind stmt 18 (Sqlite3.Data.INT (if firearm.needs_maintenance then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 19 (Sqlite3.Data.TEXT firearm.maintenance_conditions) |> ignore;
    (match firearm.last_cleaned_at with Some t -> Sqlite3.bind stmt 20 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 20 (Sqlite3.Data.NULL)) |> ignore;
    (match firearm.last_oiled_at with Some t -> Sqlite3.bind stmt 21 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 21 (Sqlite3.Data.NULL)) |> ignore;
    Sqlite3.bind stmt 22 (Sqlite3.Data.INT firearm.created_at) |> ignore;
    Sqlite3.bind stmt 23 (Sqlite3.Data.INT firearm.updated_at) |> ignore;
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
    let stmt = Sqlite3.prepare conn {sql|
      SELECT * FROM firearms
      WHERE transfer_status = 'OWNED' OR transfer_status IS NULL
      ORDER BY name
    |sql} in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
          let get_bool i = match row i with Sqlite3.Data.INT x -> x <> 0L | _ -> false in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
          let firearm : Firearm.t = {
            id = Id.of_int64 (Int64.of_int (get_int 0));
            name = get_string 1;
            caliber = get_string 2;
            serial_number = get_string 3;
            purchase_date = Id.of_int64 (Int64.of_int (get_int 4));
            notes = get_opt_string 5;
            status = get_string 6;
            is_nfa = get_bool 7;
            nfa_type = if get_string 8 = "" then None else Some (get_string 8);
            tax_stamp_id = get_string 9;
            form_type = get_string 10;
            barrel_length = get_string 11;
            trust_name = get_string 12;
            transfer_status = get_string 13;
            rounds_fired = get_int 14;
            clean_interval_rounds = get_int 15;
            oil_interval_days = get_int 16;
            needs_maintenance = get_bool 17;
            maintenance_conditions = get_string 18;
            last_cleaned_at = get_opt_int 19;
            last_oiled_at = get_opt_int 20;
            created_at = Id.of_int64 (Int64.of_int (get_int 21));
            updated_at = Id.of_int64 (Int64.of_int (get_int 22));
          } in
          collect (firearm :: acc)
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
    let stmt = Sqlite3.prepare conn "SELECT * FROM firearms WHERE id = ? LIMIT 1" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
          let get_bool i = match row i with Sqlite3.Data.INT x -> x <> 0L | _ -> false in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
          Ok (Some ({
            Firearm.id = Id.of_int64 (Int64.of_int (get_int 0));
            Firearm.name = get_string 1;
            Firearm.caliber = get_string 2;
            Firearm.serial_number = get_string 3;
            Firearm.purchase_date = Id.of_int64 (Int64.of_int (get_int 4));
            Firearm.notes = get_opt_string 5;
            Firearm.status = get_string 6;
            Firearm.is_nfa = get_bool 7;
            Firearm.nfa_type = if get_string 8 = "" then None else Some (get_string 8);
            Firearm.tax_stamp_id = get_string 9;
            Firearm.form_type = get_string 10;
            Firearm.barrel_length = get_string 11;
            Firearm.trust_name = get_string 12;
            Firearm.transfer_status = get_string 13;
            Firearm.rounds_fired = get_int 14;
            Firearm.clean_interval_rounds = get_int 15;
            Firearm.oil_interval_days = get_int 16;
            Firearm.needs_maintenance = get_bool 17;
            Firearm.maintenance_conditions = get_string 18;
            Firearm.last_cleaned_at = get_opt_int 19;
            Firearm.last_oiled_at = get_opt_int 20;
            Firearm.created_at = Id.of_int64 (Int64.of_int (get_int 21));
            Firearm.updated_at = Id.of_int64 (Int64.of_int (get_int 22));
          } : Firearm.t))
      | _ -> Ok None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_status id status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE firearms SET status = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_rounds id rounds =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE firearms SET rounds_fired = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int rounds)) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let log_maintenance id rounds_fired last_cleaned last_oiled needs_maintenance =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {sql|
      UPDATE firearms SET rounds_fired = ?, last_cleaned_at = ?, last_oiled_at = ?,
        needs_maintenance = ?, updated_at = ? WHERE id = ?
    |sql} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int rounds_fired)) |> ignore;
    (match last_cleaned with Some t -> Sqlite3.bind stmt 2 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 2 Sqlite3.Data.NULL) |> ignore;
    (match last_oiled with Some t -> Sqlite3.bind stmt 3 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 3 Sqlite3.Data.NULL) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT (if needs_maintenance then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM firearms WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
