(* gearTracker_ml - Transfer Repository *)

type transfer = {
  id : Id.t;
  firearm_id : Id.t;
  transfer_date : Timestamp.t;
  buyer_name : string;
  buyer_address : string;
  buyer_dl_number : string;
  buyer_ltc_number : string option;
  sale_price : float option;
  ffl_dealer : string option;
  ffl_license : string option;
  notes : string option;
  created_at : Timestamp.t;
}

let create_transfer
    ?(buyer_ltc_number = None)
    ?(sale_price = None)
    ?(ffl_dealer = None)
    ?(ffl_license = None)
    ?(notes = None)
    id
    firearm_id
    transfer_date
    buyer_name
    buyer_address
    buyer_dl_number
  =
  let now = Timestamp.now () in
  {
    id;
    firearm_id;
    transfer_date;
    buyer_name;
    buyer_address;
    buyer_dl_number;
    buyer_ltc_number;
    sale_price;
    ffl_dealer;
    ffl_license;
    notes;
    created_at = now;
  }

let add (transfer : transfer) =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      INSERT INTO transfers (id, firearm_id, transfer_date, buyer_name, buyer_address,
        buyer_dl_number, buyer_ltc_number, sale_price, ffl_dealer, ffl_license, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    |} in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT transfer.id) |> ignore;
    Sqlite3.bind stmt 2 (Sqlite3.Data.INT transfer.firearm_id) |> ignore;
    Sqlite3.bind stmt 3 (Sqlite3.Data.INT transfer.transfer_date) |> ignore;
    Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT transfer.buyer_name) |> ignore;
    Sqlite3.bind stmt 5 (Sqlite3.Data.TEXT transfer.buyer_address) |> ignore;
    Sqlite3.bind stmt 6 (Sqlite3.Data.TEXT transfer.buyer_dl_number) |> ignore;
    Sqlite3.bind stmt 7 (Sqlite3.Data.TEXT (Option.value transfer.buyer_ltc_number ~default:"")) |> ignore;
    Sqlite3.bind stmt 8 (Sqlite3.Data.FLOAT (Option.value transfer.sale_price ~default:0.0)) |> ignore;
    Sqlite3.bind stmt 9 (Sqlite3.Data.TEXT (Option.value transfer.ffl_dealer ~default:"")) |> ignore;
    Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT (Option.value transfer.ffl_license ~default:"")) |> ignore;
    Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT (Option.value transfer.notes ~default:"")) |> ignore;
    Sqlite3.bind stmt 12 (Sqlite3.Data.INT transfer.created_at) |> ignore;
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
    let stmt = Sqlite3.prepare conn "SELECT * FROM transfers ORDER BY transfer_date DESC" in
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_float i = match row i with Sqlite3.Data.FLOAT f -> Some f | _ -> None in
        let t : transfer = {
          id = Id.of_int64 (Int64.of_int (get_int 0));
          firearm_id = Id.of_int64 (Int64.of_int (get_int 1));
          transfer_date = Id.of_int64 (Int64.of_int (get_int 2));
          buyer_name = get_string 3;
          buyer_address = get_string 4;
          buyer_dl_number = get_string 5;
          buyer_ltc_number = get_opt_string 6;
          sale_price = get_float 7;
          ffl_dealer = get_opt_string 8;
          ffl_license = get_opt_string 9;
          notes = get_opt_string 10;
          created_at = Id.of_int64 (Int64.of_int (get_int 11));
        } in
        collect (t :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let get_by_firearm_id firearm_id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "SELECT * FROM transfers WHERE firearm_id = ? ORDER BY transfer_date DESC" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT firearm_id) |> ignore;
    let rec collect acc =
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> acc
      | Sqlite3.Rc.ROW ->
        let row i = Sqlite3.column stmt i in
        let get_int i = match row i with Sqlite3.Data.INT x -> Int64.to_int x | _ -> 0 in
        let get_string i = match row i with Sqlite3.Data.TEXT s -> s | _ -> "" in
        let get_opt_string i = match row i with Sqlite3.Data.TEXT s -> Some s | Sqlite3.Data.NULL -> None | _ -> None in
        let get_float i = match row i with Sqlite3.Data.FLOAT f -> Some f | _ -> None in
        let t : transfer = {
          id = Id.of_int64 (Int64.of_int (get_int 0));
          firearm_id = Id.of_int64 (Int64.of_int (get_int 1));
          transfer_date = Id.of_int64 (Int64.of_int (get_int 2));
          buyer_name = get_string 3;
          buyer_address = get_string 4;
          buyer_dl_number = get_string 5;
          buyer_ltc_number = get_opt_string 6;
          sale_price = get_float 7;
          ffl_dealer = get_opt_string 8;
          ffl_license = get_opt_string 9;
          notes = get_opt_string 10;
          created_at = Id.of_int64 (Int64.of_int (get_int 11));
        } in
        collect (t :: acc)
      | _ -> raise (Failure "Unexpected sqlite result")
    in
    let result = collect [] in
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok result
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))

let delete id =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn "DELETE FROM transfers WHERE id = ?" in
    Sqlite3.bind stmt 1 (Sqlite3.Data.INT id) |> ignore;
    ignore (Sqlite3.step stmt);
    ignore (Sqlite3.finalize stmt);
    Database.close_db conn;
    Ok ()
  with e ->
    Database.close_db conn;
    Error (Error.repository_database_error (Printexc.to_string e))
