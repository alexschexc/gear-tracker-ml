(* gearTracker_ml - Loadout Service *)

type validation_result =
  | Valid
  | Item_not_available of string
  | Item_needs_maintenance of string * string list
  | Insufficient_consumable of string * int * int

let validate_checkout loadout_id =
  let items_result = LoadoutRepo.get_loadout_items loadout_id in
  match items_result with
  | Error e -> Error e
  | Ok items ->
      let rec check_items acc = function
        | [] -> Ok (List.rev acc)
        | item :: rest ->
            let availability_result = CheckoutService.is_item_available item.Loadout.item_id item.Loadout.item_type in
            match availability_result with
            | Error e -> Error e
            | Ok false -> check_items (Item_not_available (Id.to_string item.Loadout.item_id) :: acc) rest
            | Ok true ->
                let maint_result = CheckoutService.check_maintenance_status item.Loadout.item_id item.Loadout.item_type in
                match maint_result with
                | Error (Error.Dom (Error.Maintenance_required { entity = _; name; reasons })) ->
                    check_items (Item_needs_maintenance (name, reasons) :: acc) rest
                | _ -> check_items acc rest
      in
      check_items [] items

let create_loadout name description notes =
  let loadout = Loadout.create_loadout ?description ?notes ~id:(Id.generate ()) name (Timestamp.now ()) in
  LoadoutRepo.add_loadout loadout

let get_all_loadouts () =
  LoadoutRepo.get_all_loadouts ()

let get_loadout_by_id id =
  LoadoutRepo.get_loadout_by_id id

let delete_loadout id =
  let items_result = LoadoutRepo.get_loadout_items id in
  match items_result with
  | Ok [] ->
    let consumables_result = LoadoutRepo.get_loadout_consumables id in
    begin match consumables_result with
    | Ok [] -> LoadoutRepo.delete_loadout id
    | Ok _ ->
      let _ = LoadoutRepo.delete_loadout_consumables_by_loadout id in
      LoadoutRepo.delete_loadout id
    | Error e -> Error e
    end
  | Ok _ ->
    let _ = LoadoutRepo.delete_loadout_items_by_loadout id in
    let consumables_result = LoadoutRepo.get_loadout_consumables id in
    begin match consumables_result with
    | Ok [] -> LoadoutRepo.delete_loadout id
    | Ok _ ->
      let _ = LoadoutRepo.delete_loadout_consumables_by_loadout id in
      LoadoutRepo.delete_loadout id
    | Error e -> Error e
    end
  | Error e -> Error e

let add_item_to_loadout loadout_id item_id item_type notes =
  let item = Loadout.create_loadout_item ~id:(Id.generate ()) ~notes loadout_id item_id item_type in
  LoadoutRepo.add_loadout_item item

let remove_item_from_loadout item_id =
  LoadoutRepo.delete_loadout_item item_id

let add_consumable_to_loadout loadout_id consumable_id quantity notes =
  let consumable = Loadout.create_loadout_consumable ~id:(Id.generate ()) ?notes loadout_id consumable_id quantity in
  LoadoutRepo.add_loadout_consumable consumable

let remove_consumable_from_loadout consumable_id =
  LoadoutRepo.delete_loadout_consumable consumable_id

let checkout_loadout loadout_id borrower_name notes =
  let loadout_result = LoadoutRepo.get_loadout_by_id loadout_id in
  match loadout_result with
  | Error e -> Error e
  | Ok loadout ->
      let items_result = LoadoutRepo.get_loadout_items loadout_id in
      match items_result with
      | Error e -> Error e
      | Ok items ->
          let borrower_result = CheckoutRepo.get_borrower_by_name borrower_name in
          let borrower_id = match borrower_result with
            | Ok (Some b) -> b.Checkout.id
            | _ ->
                let new_borrower = Checkout.create_borrower ~id:(Id.generate ()) ~phone:"" ~email:"" ~notes:None borrower_name in
                (match CheckoutRepo.add_borrower new_borrower with Ok () -> new_borrower.Checkout.id | Error _ -> Id.generate ())
          in
          let checkout_date = Timestamp.now () in
          let results = List.map (fun (item : Loadout.loadout_item) ->
              let checkout = Checkout.create_checkout
                  ~id:(Id.generate ())
                  ~expected_return:None ~notes
                  item.Loadout.item_id item.Loadout.item_type borrower_id checkout_date
              in
              CheckoutRepo.add_checkout checkout
            ) items
          in
          let all_ok = List.for_all (function Ok _ -> true | Error _ -> false) results in
           if all_ok then
             let lc = Loadout.create_loadout_checkout
                 ~id:(Id.generate ())
                 ~return_date:None ~rounds_fired:0 ~rain_exposure:false ~ammo_type:"" ~notes
                 loadout_id borrower_id checkout_date
             in
             LoadoutRepo.add_loadout_checkout lc
          else
            Error (Error.domain_item_not_available "loadout" loadout.name "Some items not available")

let return_loadout loadout_id rounds_fired rain_exposure ammo_type notes =
  let items_result = LoadoutRepo.get_loadout_items loadout_id in
  match items_result with
  | Error e -> Error e
  | Ok items ->
      let item_ids = List.map (fun (item : Loadout.loadout_item) -> item.Loadout.item_id) items in
      let checkouts_result = CheckoutRepo.get_active_checkouts_by_item_ids item_ids in
      match checkouts_result with
      | Error e -> Error e
      | Ok checkouts ->
          let return_date = Timestamp.now () in
          let results = List.map (fun (checkout : Checkout.checkout) ->
              CheckoutService.return_item checkout.Checkout.id
            ) checkouts
          in
          let all_ok = List.for_all (function Ok _ -> true | Error _ -> false) results in
          if all_ok then
            LoadoutRepo.update_loadout_checkout_return loadout_id return_date rounds_fired rain_exposure ammo_type notes
          else
            Error (Error.repository_database_error "Failed to return all items")

let get_loadout_items loadout_id =
  LoadoutRepo.get_loadout_items loadout_id

let get_loadout_consumables loadout_id =
  LoadoutRepo.get_loadout_consumables loadout_id

let get_loadout_checkouts loadout_id =
  LoadoutRepo.get_loadout_checkouts loadout_id
