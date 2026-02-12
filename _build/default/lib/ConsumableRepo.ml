(* gearTracker_ml - Consumable Repository *)

let add (consumable : Consumable.consumable) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO consumables (id, name, category, unit, quantity, min_quantity, notes, purchase_price, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT consumable.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT consumable.name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT consumable.category) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT consumable.unit) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.INT (Int64.of_int consumable.quantity)) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT (Int64.of_int consumable.min_quantity)) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.TEXT (Option.value consumable.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.FLOAT (Option.value consumable.purchase_price ~default:0.0)) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.INT consumable.created_at) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.INT consumable.updated_at) |> ignore;
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
    let stmt = Sqlite3.prepare conn "SELECT * FROM consumables ORDER BY category, name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let consumable : Consumable.consumable = {
          Consumable.id = Id.of_int64 (Int64.of_int (get_int 0));
          Consumable.name = get_string 1;
          Consumable.category = get_string 2;
          Consumable.unit = get_string 3;
          Consumable.quantity = get_int 4;
          Consumable.min_quantity = get_int 5;
          Consumable.notes = get_opt_string 6;
          Consumable.purchase_price = None;
          Consumable.created_at = Id.of_int64 (Int64.of_int (get_int 7));
          Consumable.updated_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (consumable :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let update_quantity consumable_id delta _transaction_type _notes =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      UPDATE consumables SET quantity = quantity + ? WHERE id = ?
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int delta)) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT consumable_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete consumable_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM consumables WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT consumable_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_low_stock () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM consumables WHERE quantity <= min_quantity ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let consumable : Consumable.consumable = {
          Consumable.id = Id.of_int64 (Int64.of_int (get_int 0));
          Consumable.name = get_string 1;
          Consumable.category = get_string 2;
          Consumable.unit = get_string 3;
          Consumable.quantity = get_int 4;
          Consumable.min_quantity = get_int 5;
          Consumable.notes = get_opt_string 6;
          Consumable.purchase_price = None;
          Consumable.created_at = Id.of_int64 (Int64.of_int (get_int 7));
          Consumable.updated_at = Id.of_int64 (Int64.of_int (get_int 8));
        } in
        collect (consumable :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
