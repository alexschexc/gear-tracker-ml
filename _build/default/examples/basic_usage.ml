(* basic_usage.ml - Basic usage examples for GearTracker-ml library *)

open GearTracker_ml

let () =
  Printf.printf "=== GearTracker-ml Basic Usage Examples ===\n\n";
  
  (* Initialize database *)
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/example.db" in
  Database.set_db_path db_path;
  
  (* Ensure directory exists *)
  let dir = Filename.dirname db_path in
  (try Unix.mkdir dir 0o755 with _ -> ());
  
  (* Initialize schema *)
  (match Database.open_db () with
   | db ->
       Database.init_schema db;
       Database.close_db db;
       Printf.printf "Database initialized at: %s\n\n" db_path
   | exception e ->
       Printf.printf "Note: Using existing database\n\n");
  
  (* Example 1: Create a firearm *)
  Printf.printf "1. Creating a firearm...\n";
  let firearm_id = Id.generate () in
  let now = Timestamp.now () in
  
  let ar15 : Firearm.t = {
    Firearm.id = firearm_id;
    name = "AR-15 Build";
    caliber = "5.56mm NATO";
    serial_number = "SN123456789";
    purchase_date = now;
    notes = Some "Custom build with Magpul furniture";
    status = "AVAILABLE";
    is_nfa = false;
    nfa_type = None;
    tax_stamp_id = "";
    form_type = "";
    barrel_length = "16\"";
    trust_name = "";
    transfer_status = "OWNED";
    rounds_fired = 0;
    clean_interval_rounds = 500;
    oil_interval_days = 90;
    needs_maintenance = false;
    maintenance_conditions = "";
    last_cleaned_at = None;
    last_oiled_at = None;
    created_at = now;
    updated_at = now;
  } in
  
  (match FirearmRepo.add ar15 with
   | Ok () -> Printf.printf "   Created: %s (%s)\n" ar15.name ar15.caliber
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 2: Log maintenance *)
  Printf.printf "\n2. Logging maintenance...\n";
  (match MaintenanceService.log_cleaning firearm_id "FIREARM" () with
   | Ok () -> Printf.printf "   Logged cleaning\n"
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (match MaintenanceService.log_fired_rounds firearm_id "FIREARM" 200 () with
   | Ok () -> Printf.printf "   Logged 200 rounds fired\n"
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 3: Create consumable (ammunition) *)
  Printf.printf "\n3. Creating consumable (ammunition)...\n";
  let ammo_id = Id.generate () in
  let ammo : Consumable.consumable = {
    Consumable.id = ammo_id;
    name = "5.56mm FMJ";
    category = "ammunition";
    unit = "rounds";
    quantity = 1000;
    min_quantity = 200;
    notes = Some "PMC Bronze 55gr";
    purchase_price = Some 0.35;
    created_at = now;
    updated_at = now;
  } in
  
  (match ConsumableRepo.add ammo with
   | Ok () -> Printf.printf "   Created: %s (%d %s)\n" ammo.name ammo.quantity ammo.unit
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 4: Update consumable quantity *)
  Printf.printf "\n4. Using ammunition...\n";
  (match ConsumableRepo.update_quantity ammo_id 200 "USE" (Some "Range day") with
   | Ok () ->
       (match ConsumableRepo.get_by_id ammo_id with
        | Ok (Some a) -> Printf.printf "   Updated quantity: %d %s remaining\n" a.quantity a.unit
        | _ -> ())
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 5: Create a loadout *)
  Printf.printf "\n5. Creating a loadout...\n";
  let loadout_id = Id.generate () in
  let range_day_loadout : Loadout.loadout = {
    Loadout.id = loadout_id;
    name = "Range Day Setup";
    description = Some "Basic range day equipment";
    created_date = now;
    notes = None;
    updated_at = now;
  } in
  
  (match LoadoutRepo.add_loadout range_day_loadout with
   | Ok () -> Printf.printf "   Created loadout: %s\n" range_day_loadout.name
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Add firearm to loadout *)
  let loadout_item : Loadout.loadout_item = {
    Loadout.id = Id.generate ();
    loadout_id = loadout_id;
    item_id = firearm_id;
    item_type = "FIREARM";
    notes = Some "Primary rifle";
  } in
  
  (match LoadoutRepo.add_loadout_item loadout_item with
   | Ok () -> Printf.printf "   Added firearm to loadout\n"
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 6: List all firearms *)
  Printf.printf "\n6. Listing all firearms...\n";
  (match FirearmRepo.get_all () with
   | Ok firearms ->
       Printf.printf "   Found %d firearm(s):\n" (List.length firearms);
       List.iter (fun (f : Firearm.t) ->
         Printf.printf "     - %s (%s) - %d rounds fired\n" f.name f.caliber f.rounds_fired
       ) firearms
   | Error e -> Printf.printf "   Error: %s\n" (Error.to_string e));
  
  (* Example 7: Check maintenance status *)
  Printf.printf "\n7. Checking maintenance status...\n";
  let (needs_it, _reasons) = MaintenanceService.needs_maintenance_soon firearm_id in
  if needs_it then
    Printf.printf "   Firearm needs maintenance soon\n"
  else
    Printf.printf "   Firearm maintenance status: OK\n";
  
  Printf.printf "\n=== Examples Complete ===\n"
