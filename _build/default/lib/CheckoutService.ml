(* gearTracker_ml - Checkout Service *)

let is_item_available item_id _item_type =
  let checkout_result = CheckoutRepo.get_checkout_by_item item_id in
  match checkout_result with
  | Ok (Some _) -> Ok false
  | Ok None -> Ok true
  | Error e -> Error e

let check_maintenance_status item_id item_type =
  if item_type = "FIREARM" then
    let status_result = FirearmRepo.get_maintenance_status item_id in
    match status_result with
    | Ok (Some status) ->
        if status.needs_maintenance then
          Error (Error.domain_maintenance_required "Firearm" (Printf.sprintf "%Ld" item_id) status.reasons)
        else Ok (Some status)
    | Ok None -> Error (Error.repository_not_found "Firearm" item_id)
    | Error e -> Error e
  else if item_type = "NFA_ITEM" then
    let nfa_result = NFAItemRepo.get_by_id item_id in
    match nfa_result with
    | Ok (Some nfa) ->
        if nfa.needs_maintenance then
          let reason = Option.value nfa.maintenance_conditions ~default:"Maintenance required" in
          Error (Error.domain_maintenance_required "NFA Item" nfa.nfa_name [reason])
        else Ok None
    | Ok None -> Error (Error.repository_not_found "NFA Item" item_id)
    | Error e -> Error e
  else Ok None

let checkout_item item_id item_type borrower_name expected_return notes =
  let availability_result = is_item_available item_id item_type in
  match availability_result with
  | Error e -> Error e
  | Ok false -> Error (Error.domain_item_already_checked_out "Item" "Item is already checked out")
  | Ok true ->
      let maint_result = check_maintenance_status item_id item_type in
      match maint_result with
      | Error e -> Error e
      | Ok _ ->
          let borrower_result = CheckoutRepo.get_borrower_by_name borrower_name in
          match borrower_result with
          | Error e -> Error e
          | Ok None ->
              let borrower = Checkout.create_borrower
                  ~id:(Id.generate ())
                  ~phone:"" ~email:"" ~notes:None
                  borrower_name
              in
              let open_result = CheckoutRepo.add_borrower borrower in
              begin match open_result with
              | Error e -> Error e
              | Ok () ->
                  let checkout_date = Timestamp.now () in
                  let checkout = Checkout.create_checkout
                      ~id:(Id.generate ())
                      ~expected_return ~notes
                      item_id item_type borrower.id checkout_date
                  in
                  CheckoutRepo.add_checkout checkout
              end
          | Ok (Some borrower) ->
              let checkout_date = Timestamp.now () in
              let checkout = Checkout.create_checkout
                  ~id:(Id.generate ())
                  ~expected_return ~notes
                  item_id item_type borrower.id checkout_date
              in
              CheckoutRepo.add_checkout checkout

let return_item ?rounds_fired checkout_id =
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
          match rounds_fired with
          | Some rounds when item_type = "FIREARM" ->
              FirearmRepo.update_rounds item_id rounds
          | Some rounds when item_type = "NFA_ITEM" ->
              NFAItemRepo.update_rounds_fired item_id rounds
          | _ -> Ok ()

let get_active_checkouts () =
  CheckoutRepo.get_active_checkouts ()

let get_checkout_history () =
  CheckoutRepo.get_checkout_history ()

let get_checkout_by_item item_id =
  CheckoutRepo.get_checkout_by_item item_id

let get_borrower_checkouts borrower_id =
  CheckoutRepo.get_borrower_checkouts borrower_id

let add_borrower name phone email notes =
  let borrower = Checkout.create_borrower ~id:(Id.generate ()) ~phone ~email ~notes name in
  CheckoutRepo.add_borrower borrower

let get_all_borrowers () =
  CheckoutRepo.get_all_borrowers ()

let delete_borrower borrower_id =
  CheckoutRepo.delete_borrower borrower_id
