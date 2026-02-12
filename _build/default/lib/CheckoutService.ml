(* gearTracker_ml - Checkout Service *)

let checkout_item item_id item_type borrower_id expected_return notes =
  let borrower_result = CheckoutRepo.get_borrower_by_name borrower_id in
  match borrower_result with
  | Error e -> Error e
  | Ok None ->
    let borrower = Checkout.create_borrower
        ~phone:"" ~email:"" ~notes:None
        (Id.generate ()) borrower_id
    in
    let open_result = CheckoutRepo.add_borrower borrower in
    begin match open_result with
    | Error e -> Error e
    | Ok () ->
      let checkout_date = Timestamp.now () in
      let checkout = Checkout.create_checkout
          ~expected_return ~notes
          (Id.generate ()) item_id item_type borrower.id checkout_date
      in
      CheckoutRepo.add_checkout checkout
    end
  | Ok (Some borrower) ->
    let checkout_date = Timestamp.now () in
    let checkout = Checkout.create_checkout
        ~expected_return ~notes
        (Id.generate ()) item_id item_type borrower.id checkout_date
    in
    CheckoutRepo.add_checkout checkout

let return_item checkout_id =
  let checkout_result = CheckoutRepo.get_checkout_by_id checkout_id in
  match checkout_result with
  | Error e -> Error e
  | Ok checkout ->
    let item_type = checkout.item_type in
    let item_id = checkout.item_id in
    let return_result = CheckoutRepo.return_item checkout_id in
    match return_result with
    | Error e -> Error e
    | Ok () ->
      if item_type = "FIREARM" then
        FirearmRepo.update_rounds item_id 0
      else if item_type = "NFA_ITEM" then
        GearRepo.update_nfa_item_rounds_fired item_id 0
      else
        Ok ()

let get_active_checkouts () =
  CheckoutRepo.get_active_checkouts ()

let get_checkout_history () =
  let conn = Database.open_db () in
  try
    let stmt = Sqlite3.prepare conn {|
      SELECT c.*, b.name as borrower_name
      FROM checkouts c
      JOIN borrowers b ON c.borrower_id = b.id
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

let get_borrower_checkouts borrower_id =
  CheckoutRepo.get_borrower_checkouts borrower_id

let add_borrower name phone email notes =
  let borrower = Checkout.create_borrower ~phone ~email ~notes (Id.generate ()) name in
  CheckoutRepo.add_borrower borrower

let get_all_borrowers () =
  CheckoutRepo.get_all_borrowers ()

let delete_borrower borrower_id =
  let active_checkouts = CheckoutRepo.get_borrower_active_checkouts borrower_id in
  match active_checkouts with
  | Ok [] -> CheckoutRepo.delete_borrower borrower_id
  | Ok _ -> Error (Error.domain_borrower_has_active_checkouts borrower_id)
  | Error e -> Error e
