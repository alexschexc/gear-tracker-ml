(* gearTracker_ml - Maintenance Service *)

let log_maintenance item_id item_type log_type details ammo_count photo_path =
  let date = Timestamp.now () in
  let maintenance_log = Checkout.create_maintenance_log
      ~details ~ammo_count ~photo_path
      (Id.generate ()) item_id item_type log_type date
  in
  CheckoutRepo.add_maintenance_log maintenance_log

let log_cleaning item_id item_type details ammo_count photo_path =
  log_maintenance item_id item_type "CLEANING" details ammo_count photo_path

let log_oil_change item_id item_type details ammo_count photo_path =
  log_maintenance item_id item_type "OIL_CHANGE" details ammo_count photo_path

let log_inspection item_id item_type details ammo_count photo_path =
  log_maintenance item_id item_type "INSPECTION" details ammo_count photo_path

let get_maintenance_history item_id item_type =
  CheckoutRepo.get_maintenance_history item_id item_type

let get_all_maintenance () =
  CheckoutRepo.get_all_maintenance ()
