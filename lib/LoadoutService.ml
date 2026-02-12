(* gearTracker_ml - Loadout Service *)

let create_loadout name description notes =
  let loadout = Loadout.create_loadout ?description ?notes (Id.generate ()) name (Timestamp.now ()) in
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
  let item = Loadout.create_loadout_item ?notes (Id.generate ()) loadout_id item_id item_type in
  LoadoutRepo.add_loadout_item item

let remove_item_from_loadout item_id =
  LoadoutRepo.delete_loadout_item item_id

let add_consumable_to_loadout loadout_id consumable_id quantity notes =
  let consumable = Loadout.create_loadout_consumable ?notes (Id.generate ()) loadout_id consumable_id quantity in
  LoadoutRepo.add_loadout_consumable consumable

let remove_consumable_from_loadout consumable_id =
  LoadoutRepo.delete_loadout_consumable consumable_id

let checkout_loadout loadout_id borrower_id notes =
  let loadout_result = LoadoutRepo.get_loadout_by_id loadout_id in
  match loadout_result with
  | Error e -> Error e
  | Ok loadout ->
    let items_result = LoadoutRepo.get_loadout_items loadout_id in
    match items_result with
    | Error e -> Error e
    | Ok items ->
      let consumables_result = LoadoutRepo.get_loadout_consumables loadout_id in
      begin match consumables_result with
      | Error e -> Error e
      | Ok _consumables ->
        let results = List.map (fun (item : Loadout.loadout_item) ->
            CheckoutService.checkout_item item.Loadout.item_id item.Loadout.item_type borrower_id None notes
          ) items
        in
        let all_ok = List.for_all (function Ok _ -> true | Error _ -> false) results in
        if all_ok then
          let lc = Loadout.create_loadout_checkout
              ~return_date:None ~rounds_fired:0 ~rain_exposure:false ~ammo_type:"" ~notes
              (Id.generate ()) loadout_id 0L
          in
          LoadoutRepo.add_loadout_checkout lc
        else
          Error (Error.domain_item_not_available "loadout" loadout.name "Some items not available")
      end

let return_loadout loadout_checkout_id rounds_fired rain_exposure ammo_type notes =
  let loadout_checkouts_result = LoadoutRepo.get_loadout_checkouts loadout_checkout_id in
  match loadout_checkouts_result with
  | Error e -> Error e
  | Ok checkouts ->
    let return_date = Timestamp.now () in
    let results = List.map (fun lc ->
        CheckoutService.return_item lc.Loadout.checkout_id
      ) checkouts
    in
    let all_ok = List.for_all (fun r -> r = Ok ()) results in
    if all_ok then
      LoadoutRepo.update_loadout_checkout_return loadout_checkout_id (Some (Int64.to_int return_date)) rounds_fired rain_exposure ammo_type notes
    else
      Error (Error.repository_database_error "Failed to return all items")

let get_loadout_items loadout_id =
  LoadoutRepo.get_loadout_items loadout_id

let get_loadout_consumables loadout_id =
  LoadoutRepo.get_loadout_consumables loadout_id

let get_loadout_checkouts loadout_id =
  LoadoutRepo.get_loadout_checkouts loadout_id
