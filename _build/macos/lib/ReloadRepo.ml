(* gearTracker_ml - Reload Repository *)

let add_reload_batch (batch : Reload.reload_batch) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO reload_batches (id, cartridge, firearm_id, date_created, bullet_maker, bullet_model,
        bullet_weight_gr, powder_name, powder_charge_gr, powder_lot, primer_maker, primer_type,
        case_brand, case_times_fired, case_prep_notes, coal_in, crimp_style, test_date, avg_velocity,
        es, sd, group_size_inches, group_distance_yards, intended_use, status, notes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    let open Reload in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT batch.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT batch.cartridge) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT (Option.value ~default:0L batch.firearm_id)) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT batch.date_created) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT batch.bullet_maker) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT batch.bullet_model) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Option.value ~default:0L (batch.bullet_weight_gr |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT batch.powder_name) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.FLOAT (Option.value ~default:0.0 batch.powder_charge_gr)) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT batch.powder_lot) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT batch.primer_maker) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.TEXT batch.primer_type) |> ignore;
    Sqlite3.bind stmt 13 (Sqlite3.Data.TEXT batch.case_brand) |> ignore;
    Sqlite3.bind stmt 14 (Sqlite3.Data.INT (Option.value ~default:0L (batch.case_times_fired |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 15 (Sqlite3.Data.TEXT batch.case_prep_notes) |> ignore;
    Sqlite3.bind stmt 16 (Sqlite3.Data.FLOAT (Option.value ~default:0.0 batch.coal_in)) |> ignore;
    Sqlite3.bind stmt 17 (Sqlite3.Data.TEXT batch.crimp_style) |> ignore;
    Sqlite3.bind stmt 18 (Sqlite3.Data.INT (Option.value ~default:0L batch.test_date)) |> ignore;
    Sqlite3.bind stmt 19 (Sqlite3.Data.INT (Option.value ~default:0L (batch.avg_velocity |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 20 (Sqlite3.Data.INT (Option.value ~default:0L (batch.es |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 21 (Sqlite3.Data.INT (Option.value ~default:0L (batch.sd |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 22 (Sqlite3.Data.FLOAT (Option.value ~default:0.0 batch.group_size_inches)) |> ignore;
    Sqlite3.bind stmt 23 (Sqlite3.Data.INT (Option.value ~default:0L (batch.group_distance_yards |> Option.map Int64.of_int))) |> ignore;
    Sqlite3.bind stmt 24 (Sqlite3.Data.TEXT batch.intended_use) |> ignore;
    Sqlite3.bind stmt 25 (Sqlite3.Data.TEXT batch.status) |> ignore;
    Sqlite3.bind stmt 26 (Sqlite3.Data.TEXT (Option.value ~default:"" batch.notes)) |> ignore;
    Sqlite3.bind stmt 27 (Sqlite3.Data.INT batch.created_at) |> ignore;
    Sqlite3.bind stmt 28 (Sqlite3.Data.INT batch.updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_reload_batches () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM reload_batches ORDER BY date_created DESC" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_float i = match row i with Sqlite3.Data.FLOAT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let batch : Reload.reload_batch = {
          Reload.id = Id.of_int64 (Int64.of_int (get_int 0));
          Reload.cartridge = get_string 1;
          Reload.firearm_id = get_int64_opt 2;
          Reload.date_created = Id.of_int64 (Int64.of_int (get_int 3));
          Reload.bullet_maker = get_string 4;
          Reload.bullet_model = get_string 5;
          Reload.bullet_weight_gr = get_opt_int 6;
          Reload.powder_name = get_string 7;
          Reload.powder_charge_gr = get_opt_float 8;
          Reload.powder_lot = get_string 9;
          Reload.primer_maker = get_string 10;
          Reload.primer_type = get_string 11;
          Reload.case_brand = get_string 12;
          Reload.case_times_fired = get_opt_int 13;
          Reload.case_prep_notes = get_string 14;
          Reload.coal_in = get_opt_float 15;
          Reload.crimp_style = get_string 16;
          Reload.test_date = get_int64_opt 17;
          Reload.avg_velocity = get_opt_int 18;
          Reload.es = get_opt_int 19;
          Reload.sd = get_opt_int 20;
          Reload.group_size_inches = get_opt_float 21;
          Reload.group_distance_yards = get_opt_int 22;
          Reload.intended_use = get_string 23;
          Reload.status = get_string 24;
          Reload.notes = get_opt_string 25;
          Reload.created_at = Id.of_int64 (Int64.of_int (get_int 26));
          Reload.updated_at = Id.of_int64 (Int64.of_int (get_int 27));
        } in
        collect (batch :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_reload_batch_by_id id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM reload_batches WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        (* let get_float i = match row i with Sqlite3.Data.FLOAT x -> x | _ -> 0.0 in *)
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_float i = match row i with Sqlite3.Data.FLOAT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let batch : Reload.reload_batch = {
          Reload.id = Id.of_int64 (Int64.of_int (get_int 0));
          Reload.cartridge = get_string 1;
          Reload.firearm_id = get_int64_opt 2;
          Reload.date_created = Id.of_int64 (Int64.of_int (get_int 3));
          Reload.bullet_maker = get_string 4;
          Reload.bullet_model = get_string 5;
          Reload.bullet_weight_gr = get_opt_int 6;
          Reload.powder_name = get_string 7;
          Reload.powder_charge_gr = get_opt_float 8;
          Reload.powder_lot = get_string 9;
          Reload.primer_maker = get_string 10;
          Reload.primer_type = get_string 11;
          Reload.case_brand = get_string 12;
          Reload.case_times_fired = get_opt_int 13;
          Reload.case_prep_notes = get_string 14;
          Reload.coal_in = get_opt_float 15;
          Reload.crimp_style = get_string 16;
          Reload.test_date = get_int64_opt 17;
          Reload.avg_velocity = get_opt_int 18;
          Reload.es = get_opt_int 19;
          Reload.sd = get_opt_int 20;
          Reload.group_size_inches = get_opt_float 21;
          Reload.group_distance_yards = get_opt_int 22;
          Reload.intended_use = get_string 23;
          Reload.status = get_string 24;
          Reload.notes = get_opt_string 25;
          Reload.created_at = Id.of_int64 (Int64.of_int (get_int 26));
          Reload.updated_at = Id.of_int64 (Int64.of_int (get_int 27));
        } in
        Some batch
      | _ -> None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    match result with
    | Some batch -> Ok batch
    | None -> Error (Error.repository_not_found "reload_batch" id)
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_reload_batches_by_status status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM reload_batches WHERE status = ? ORDER BY date_created DESC" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        (* let get_float i = match row i with Sqlite3.Data.FLOAT x -> x | _ -> 0.0 in *)
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let get_opt_float i = match row i with Sqlite3.Data.FLOAT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
        let batch : Reload.reload_batch = {
          Reload.id = Id.of_int64 (Int64.of_int (get_int 0));
          Reload.cartridge = get_string 1;
          Reload.firearm_id = get_int64_opt 2;
          Reload.date_created = Id.of_int64 (Int64.of_int (get_int 3));
          Reload.bullet_maker = get_string 4;
          Reload.bullet_model = get_string 5;
          Reload.bullet_weight_gr = get_opt_int 6;
          Reload.powder_name = get_string 7;
          Reload.powder_charge_gr = get_opt_float 8;
          Reload.powder_lot = get_string 9;
          Reload.primer_maker = get_string 10;
          Reload.primer_type = get_string 11;
          Reload.case_brand = get_string 12;
          Reload.case_times_fired = get_opt_int 13;
          Reload.case_prep_notes = get_string 14;
          Reload.coal_in = get_opt_float 15;
          Reload.crimp_style = get_string 16;
          Reload.test_date = get_int64_opt 17;
          Reload.avg_velocity = get_opt_int 18;
          Reload.es = get_opt_int 19;
          Reload.sd = get_opt_int 20;
          Reload.group_size_inches = get_opt_float 21;
          Reload.group_distance_yards = get_opt_int 22;
          Reload.intended_use = get_string 23;
          Reload.status = get_string 24;
          Reload.notes = get_opt_string 25;
          Reload.created_at = Id.of_int64 (Int64.of_int (get_int 26));
          Reload.updated_at = Id.of_int64 (Int64.of_int (get_int 27));
        } in
        collect (batch :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_reload_batch_status id status =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE reload_batches SET status = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT status) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_reload_batch id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM reload_batches WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
