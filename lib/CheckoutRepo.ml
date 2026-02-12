(* gearTracker_ml - Checkout Repository *)

let add_borrower (borrower : Checkout.borrower) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO borrowers (id, name, phone, email, notes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT borrower.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT borrower.name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT borrower.phone) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT borrower.email) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value borrower.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT borrower.created_at) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT borrower.updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_borrowers () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM borrowers ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let borrower : Checkout.borrower = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.name = get_string 1;
          Checkout.phone = get_string 2;
          Checkout.email = get_string 3;
          Checkout.notes = get_opt_string 4;
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 5));
          Checkout.updated_at = Id.of_int64 (Int64.of_int (get_int 6));
        } in
        collect (borrower :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_borrower_by_name name =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM borrowers WHERE name = ? LIMIT 1" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT name) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        Ok (Some {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.name = get_string 1;
          Checkout.phone = get_string 2;
          Checkout.email = get_string 3;
          Checkout.notes = get_opt_string 4;
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 5));
          Checkout.updated_at = Id.of_int64 (Int64.of_int (get_int 6));
        })
      | _ -> Ok None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_borrower id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM borrowers WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_checkout (checkout : Checkout.checkout) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO checkouts (id, item_id, item_type, borrower_id, checkout_date, expected_return, actual_return, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT checkout.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT checkout.item_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT checkout.item_type) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT checkout.borrower_id) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT checkout.checkout_date) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT (Option.value checkout.expected_return ~default:0L)) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Option.value checkout.actual_return ~default:0L)) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT (Option.value checkout.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.INT checkout.created_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_active_checkouts () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      SELECT c.*, b.name as borrower_name
      FROM checkouts c
      JOIN borrowers b ON c.borrower_id = b.id
      WHERE c.actual_return IS NULL
      ORDER BY c.checkout_date DESC
    |} in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let checkout : Checkout.checkout = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.borrower_id = Id.of_int64 (Int64.of_int (get_int 3));
          Checkout.checkout_date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.expected_return = if get_int 5 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 5)));
          Checkout.actual_return = None;
          Checkout.notes = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (checkout :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let return_item checkout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "UPDATE checkouts SET actual_return = ? WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Timestamp.now ())) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT checkout_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_checkout_by_id id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM checkouts WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        Some {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.borrower_id = Id.of_int64 (Int64.of_int (get_int 3));
          Checkout.checkout_date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.expected_return = if get_int 5 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 5)));
          Checkout.actual_return = if get_int 6 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 6)));
          Checkout.notes = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        }
      | _ -> None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    match result with
    | Some checkout -> Ok checkout
    | None -> Error (Error.repository_not_found "checkout" id)
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_borrower_checkouts borrower_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM checkouts WHERE borrower_id = ? ORDER BY checkout_date DESC" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT borrower_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let checkout : Checkout.checkout = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.borrower_id = Id.of_int64 (Int64.of_int (get_int 3));
          Checkout.checkout_date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.expected_return = if get_int 5 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 5)));
          Checkout.actual_return = if get_int 6 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 6)));
          Checkout.notes = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (checkout :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_borrower_active_checkouts borrower_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM checkouts WHERE borrower_id = ? AND actual_return IS NULL" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT borrower_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let checkout : Checkout.checkout = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.borrower_id = Id.of_int64 (Int64.of_int (get_int 3));
          Checkout.checkout_date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.expected_return = if get_int 5 = 0 then None else Some (Id.of_int64 (Int64.of_int (get_int 5)));
          Checkout.actual_return = None;
          Checkout.notes = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (checkout :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_maintenance_log (log : Checkout.maintenance_log) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {sql|
      INSERT INTO maintenance_logs (id, item_id, item_type, log_type, date, details, ammo_count, photo_path, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    |sql} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT log.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT log.item_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT log.item_type) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT log.log_type) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT log.date) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT (Option.value log.details ~default:"")) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (Option.value ~default:0L (Option.map Int64.of_int log.ammo_count))) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT (Option.value log.photo_path ~default:"")) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.INT log.created_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_maintenance_history item_id item_type =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM maintenance_logs WHERE item_id = ? AND item_type = ? ORDER BY date DESC" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT item_id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT item_type) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let log : Checkout.maintenance_log = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.log_type = get_string 3;
          Checkout.date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.details = if get_string 5 = "" then None else Some (get_string 5);
          Checkout.ammo_count = get_opt_int 6;
          Checkout.photo_path = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (log :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_maintenance () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM maintenance_logs ORDER BY date DESC" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_int i = match row i with Sqlite3.Data.INT x -> Some (Int64.to_int x) | Sqlite3.Data.NULL -> None | _ -> None in
        let log : Checkout.maintenance_log = {
          Checkout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Checkout.item_id = Id.of_int64 (Int64.of_int (get_int 1));
          Checkout.item_type = get_string 2;
          Checkout.log_type = get_string 3;
          Checkout.date = Id.of_int64 (Int64.of_int (get_int 4));
          Checkout.details = if get_string 5 = "" then None else Some (get_string 5);
          Checkout.ammo_count = get_opt_int 6;
          Checkout.photo_path = if get_string 7 = "" then None else Some (get_string 7);
          Checkout.created_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (log :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
