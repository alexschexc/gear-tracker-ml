(* Test runner for gearTracker *)

open Alcotest

let test_firearm_repository () =
  let module M = GearTracker_ml in
  let name = Printf.sprintf "Test Rifle %d" (Random.int 100000) in
  let now = M.Timestamp.now () in
  let id = M.Id.generate () in
  let firearm : M.Firearm.t = {
    M.Firearm.id = id;
    M.Firearm.name = name;
    M.Firearm.caliber = ".308 Win";
    M.Firearm.serial_number = name;
    M.Firearm.purchase_date = now;
    M.Firearm.notes = None;
    M.Firearm.status = "AVAILABLE";
    M.Firearm.is_nfa = false;
    M.Firearm.nfa_type = None;
    M.Firearm.tax_stamp_id = "";
    M.Firearm.form_type = "";
    M.Firearm.barrel_length = "";
    M.Firearm.trust_name = "";
    M.Firearm.transfer_status = "OWNED";
    M.Firearm.rounds_fired = 0;
    M.Firearm.clean_interval_rounds = 500;
    M.Firearm.oil_interval_days = 90;
    M.Firearm.needs_maintenance = false;
    M.Firearm.maintenance_conditions = "";
    M.Firearm.last_cleaned_at = None;
    M.Firearm.last_oiled_at = None;
    M.Firearm.created_at = now;
    M.Firearm.updated_at = now;
  } in
  let _ = M.FirearmRepo.add firearm in
  let _ = M.FirearmRepo.get_all () in
  let _ = M.FirearmRepo.get_by_id firearm.M.Firearm.id in
  let _ = M.FirearmRepo.reset_rounds firearm.M.Firearm.id in
  ()

let test_consumable_repository () =
  let module M = GearTracker_ml in
  let name = Printf.sprintf "Test Ammo %d" (Random.int 100000) in
  let cons : M.Consumable.consumable = {
    M.Consumable.id = M.Id.generate ();
    M.Consumable.name = name;
    M.Consumable.category = "ammo";
    M.Consumable.unit = "rounds";
    M.Consumable.quantity = 500;
    M.Consumable.min_quantity = 100;
    M.Consumable.notes = None;
    M.Consumable.purchase_price = None;
    M.Consumable.created_at = M.Timestamp.now ();
    M.Consumable.updated_at = M.Timestamp.now ();
  } in
  let _ = M.ConsumableRepo.add cons in
  let _ = M.ConsumableRepo.get_all () in
  let _ = M.ConsumableRepo.get_by_id cons.M.Consumable.id in
  let _ = M.ConsumableRepo.update_quantity cons.M.Consumable.id 50 "USE" (Some "Test use") in
  let _ = M.ConsumableRepo.get_history cons.M.Consumable.id in
  ()

let test_checkout_repository () =
  let module M = GearTracker_ml in
  let borrower_name = Printf.sprintf "Test Borrower %d" (Random.int 100000) in
  let borrower : M.Checkout.borrower = {
    M.Checkout.id = M.Id.generate ();
    M.Checkout.name = borrower_name;
    M.Checkout.phone = "555-1234";
    M.Checkout.email = "test@example.com";
    M.Checkout.notes = None;
    M.Checkout.created_at = M.Timestamp.now ();
    M.Checkout.updated_at = M.Timestamp.now ();
  } in
  let _ = M.CheckoutRepo.add_borrower borrower in
  let _ = M.CheckoutRepo.get_all_borrowers () in
  let _ = M.CheckoutRepo.get_borrower_by_name borrower_name in
  ()

let test_gear_repository () =
  let module M = GearTracker_ml in
  let gear_name = Printf.sprintf "Test Backpack %d" (Random.int 100000) in
  let now = M.Timestamp.now () in
  let gear : M.Gear.t = {
    M.Gear.id = M.Id.generate ();
    M.Gear.name = gear_name;
    M.Gear.category = "pack";
    M.Gear.brand = Some "Test Brand";
    M.Gear.purchase_date = now;
    M.Gear.notes = None;
    M.Gear.status = "AVAILABLE";
    M.Gear.created_at = now;
    M.Gear.updated_at = now;
  } in
  let _ = M.GearRepo.add_soft_gear gear in
  let _ = M.GearRepo.get_all_soft_gear () in
  ()

let test_maintenance_service () =
  let module M = GearTracker_ml in
  let _ = M.MaintenanceService.log_cleaning 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_fired_rounds 1L "FIREARM" 100 () in
  let _ = M.MaintenanceService.log_lubrication 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_oiling 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_repair 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_inspection 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_hunting 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_zeroing 1L "FIREARM" 100 () in
  let _ = M.MaintenanceService.log_rain_exposure 1L "FIREARM" () in
  let _ = M.MaintenanceService.log_corrosive_ammo 1L "FIREARM" "223" () in
  let _ = M.MaintenanceService.log_lead_ammo 1L "FIREARM" () in
  ()

let test_loadout_service () =
  let module M = GearTracker_ml in
  let _ = M.LoadoutService.validate_checkout 1L in
  ()

let test_checkout_service () =
  let module M = GearTracker_ml in
  let _ = M.CheckoutService.is_item_available 1L "FIREARM" in
  let _ = M.CheckoutService.check_maintenance_status 1L "FIREARM" in
  let _ = M.CheckoutService.get_active_checkouts () in
  let _ = M.CheckoutService.get_checkout_history () in
  ()

let () =
  run "gearTracker-ml" [
    "Firearm Repository", [
      test_case "add_get_reset" `Quick test_firearm_repository
    ];
    "Consumable Repository", [
      test_case "add_get_update" `Quick test_consumable_repository
    ];
    "Checkout Repository", [
      test_case "add_borrower" `Quick test_checkout_repository
    ];
    "Gear Repository", [
      test_case "add_get_gear" `Quick test_gear_repository
    ];
    "Maintenance Service", [
      test_case "log_maintenance" `Quick test_maintenance_service
    ];
    "Loadout Service", [
      test_case "validate" `Quick test_loadout_service
    ];
    "Checkout Service", [
      test_case "availability" `Quick test_checkout_service
    ];
  ]
