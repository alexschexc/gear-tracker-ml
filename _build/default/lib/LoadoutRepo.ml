(* gearTracker_ml - Loadout Repository *)

let add_loadout (loadout : Loadout.loadout) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO loadouts (id, name, description, created_date, notes, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
    |} in
    (if loadout.id = 0L then Sqlite3.bind stmt 1 Sqlite3.Data.NULL else Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout.id)) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT loadout.name) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT (Option.value loadout.description ~default:"")) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT loadout.created_date) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value loadout.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT loadout.updated_at) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_all_loadouts () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM loadouts ORDER BY name" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let loadout : Loadout.loadout = {
          Loadout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Loadout.name = get_string 1;
          Loadout.description = get_opt_string 2;
          Loadout.created_date = Id.of_int64 (Int64.of_int (get_int 3));
          Loadout.notes = get_opt_string 4;
          Loadout.updated_at = Id.of_int64 (Int64.of_int (get_int 5));
        } in
        collect (loadout :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_loadout_by_id id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM loadouts WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    let result = match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let loadout : Loadout.loadout = {
          Loadout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Loadout.name = get_string 1;
          Loadout.description = get_opt_string 2;
          Loadout.created_date = Id.of_int64 (Int64.of_int (get_int 3));
          Loadout.notes = get_opt_string 4;
          Loadout.updated_at = Id.of_int64 (Int64.of_int (get_int 5));
        } in
        Some loadout
      | _ -> None
    in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    match result with
    | Some loadout -> Ok loadout
    | None -> Error (Error.repository_not_found "loadout" id)
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_loadout id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM loadouts WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_loadout_item (item : Loadout.loadout_item) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO loadout_items (id, loadout_id, item_id, item_type, notes)
      VALUES (?, ?, ?, ?, ?)
    |} in
    (if item.id = 0L then Sqlite3.bind stmt 1 Sqlite3.Data.NULL else Sqlite3.bind stmt 1 (Sqlite3.Data.INT item.id)) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT item.loadout_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT item.item_id) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT item.item_type) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value item.notes ~default:"")) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_loadout_items loadout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM loadout_items WHERE loadout_id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let item : Loadout.loadout_item = {
          Loadout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Loadout.loadout_id = Id.of_int64 (Int64.of_int (get_int 1));
          Loadout.item_id = Id.of_int64 (Int64.of_int (get_int 2));
          Loadout.item_type = get_string 3;
          Loadout.notes = get_opt_string 4;
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

let delete_loadout_item id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM loadout_items WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_loadout_items_by_loadout loadout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM loadout_items WHERE loadout_id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_loadout_consumable (consumable : Loadout.loadout_consumable) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO loadout_consumables (id, loadout_id, consumable_id, quantity, notes)
      VALUES (?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT consumable.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT consumable.loadout_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT consumable.consumable_id) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT (Int64.of_int consumable.quantity)) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value consumable.notes ~default:"")) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_loadout_consumables loadout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM loadout_consumables WHERE loadout_id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let consumable : Loadout.loadout_consumable = {
          Loadout.id = Id.of_int64 (Int64.of_int (get_int 0));
          Loadout.loadout_id = Id.of_int64 (Int64.of_int (get_int 1));
          Loadout.consumable_id = Id.of_int64 (Int64.of_int (get_int 2));
          Loadout.quantity = get_int 3;
           Loadout.notes = get_opt_string 4;
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

let delete_loadout_consumable id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM loadout_consumables WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete_loadout_consumables_by_loadout loadout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM loadout_consumables WHERE loadout_id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let add_loadout_checkout (checkout : Loadout.loadout_checkout) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {sql|
      INSERT INTO loadout_checkouts (id, loadout_id, borrower_id, checkout_date, return_date, rounds_fired,
        rain_exposure, ammo_type, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    |sql} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT checkout.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT checkout.loadout_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT checkout.borrower_id) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.INT checkout.checkout_date) |> ignore;
    (match checkout.return_date with Some t -> Sqlite3.bind stmt 5 (Sqlite3.Data.INT t) | None -> Sqlite3.bind stmt 5 Sqlite3.Data.NULL) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT (Int64.of_int checkout.rounds_fired)) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.INT (if checkout.rain_exposure then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.TEXT checkout.ammo_type) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value ~default:"" checkout.notes)) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_loadout_checkouts loadout_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM loadout_checkouts WHERE loadout_id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT loadout_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
          let row i = Sqlite3.column stmt i in
          let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
          let get_int64 i = match row i with Sqlite3.Data.INT x -> x | _ -> 0L in
          let get_int64_opt i = match row i with Sqlite3.Data.INT x -> Some x | Sqlite3.Data.NULL -> None | _ -> None in
          let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
          let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
          let checkout : Loadout.loadout_checkout = {
            Loadout.id = get_int64 (get_int 0);
            Loadout.loadout_id = get_int64 (get_int 1);
            Loadout.borrower_id = get_int64 (get_int 2);
            Loadout.checkout_date = get_int64 (get_int 3);
            Loadout.return_date = get_int64_opt 4;
            Loadout.rounds_fired = get_int 5;
            Loadout.rain_exposure = (get_int 6 = 1);
            Loadout.ammo_type = get_string 7;
            Loadout.notes = get_opt_string 8;
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

let update_loadout_checkout_return loadout_id return_date rounds_fired rain_exposure ammo_type notes =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      UPDATE loadout_checkouts SET return_date = ?, rounds_fired = ?, rain_exposure = ?,
        ammo_type = ?, notes = ? WHERE loadout_id = ? AND return_date IS NULL
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT return_date) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT (Int64.of_int rounds_fired)) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT (if rain_exposure then 1L else 0L)) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT ammo_type) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT (Option.value ~default:"" notes)) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.INT loadout_id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))