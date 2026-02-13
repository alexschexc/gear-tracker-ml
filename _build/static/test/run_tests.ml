(* Test runner for gearTracker-ml
   
   Comprehensive test suite covering:
   - Core types and utilities
   - All repositories (CRUD operations)
   - All services (business logic)
   - Import/Export functionality
   - Integration scenarios
*)

open Alcotest

module M = GearTracker_ml

(* ============================================================================
   Helper Functions
   ============================================================================ *)

let with_test_db f () =
  (* Use a temporary database for tests *)
  let test_db_path = "/tmp/geartracker_test.db" in
  M.Database.set_db_path test_db_path;
  
  (* Initialize schema *)
  (match M.Database.open_db () with
   | db ->
       M.Database.init_schema db;
       M.Database.close_db db
   | exception _ -> ());
  
  (* Run test *)
  f ();
  
  (* Cleanup *)
  (try Sys.remove test_db_path with _ -> ())

let random_name prefix =
  Printf.sprintf "%s_%d" prefix (Random.int 1000000)

let string_contains haystack needle =
  let hlen = String.length haystack in
  let nlen = String.length needle in
  if nlen > hlen then false
  else
    let rec check i =
      if i > hlen - nlen then false
      else if String.sub haystack i nlen = needle then true
      else check (i + 1)
    in
    check 0

(* ============================================================================
   Core Type Tests
   ============================================================================ *)

let test_id_operations () =
  let id1 = M.Id.generate () in
  let id2 = M.Id.generate () in
  check bool "ids are unique" false (M.Id.equal id1 id2);
  check string "id to string" (Int64.to_string id1) (M.Id.to_string id1);
  let id_from_str = M.Id.of_string (M.Id.to_string id1) in
  check bool "id from string" true (M.Id.equal id1 id_from_str)

let test_timestamp_operations () =
  let now = M.Timestamp.now () in
  let now2 = M.Timestamp.now () in
  check bool "timestamp increases" true (now2 >= now);
  
  let iso = M.Timestamp.to_iso8601 now in
  check bool "iso8601 format" true (String.length iso = 10);
  
  (match M.Timestamp.of_iso8601 "2024-01-15" with
   | Ok ts ->
       let iso2 = M.Timestamp.to_iso8601 ts in
       check string "roundtrip iso8601" "2024-01-15" iso2
   | Error _ -> fail "Failed to parse ISO8601 date")

let test_error_types () =
  let err1 = M.Error.repository_not_found "firearm" 1L in
  let err_str = M.Error.to_string err1 in
  check bool "error contains entity" true (string_contains err_str "firearm");

  let err2 = M.Error.validation_required_field "name" in
  let err_str2 = M.Error.to_string err2 in
  check bool "validation error" true (string_contains err_str2 "required");

  let err3 = M.Error.domain_item_not_available "gear" "Backpack" "checked out" in
  let err_str3 = M.Error.to_string err3 in
  check bool "domain error" true (string_contains err_str3 "not available")

(* ============================================================================
   Repository Tests
   ============================================================================ *)

let test_firearm_repository () =
  let name = random_name "TestRifle" in
  let now = M.Timestamp.now () in
  let id = M.Id.generate () in
  
  let firearm : M.Firearm.t = {
    M.Firearm.id = id;
    M.Firearm.name = name;
    M.Firearm.caliber = ".308 Win";
    M.Firearm.serial_number = "SN" ^ name;
    M.Firearm.purchase_date = now;
    M.Firearm.notes = Some "Test firearm";
    M.Firearm.status = "AVAILABLE";
    M.Firearm.is_nfa = false;
    M.Firearm.nfa_type = None;
    M.Firearm.tax_stamp_id = "";
    M.Firearm.form_type = "";
    M.Firearm.barrel_length = "16";
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
  
  (* Add firearm *)
  (match M.FirearmRepo.add firearm with
   | Error e -> fail ("Failed to add firearm: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get all firearms *)
  (match M.FirearmRepo.get_all () with
   | Error e -> fail ("Failed to get firearms: " ^ M.Error.to_string e)
   | Ok firearms ->
       check bool "firearm in list" true
         (List.exists (fun f -> M.Id.equal f.M.Firearm.id id) firearms));
  
  (* Get by ID *)
  (match M.FirearmRepo.get_by_id id with
   | Error e -> fail ("Failed to get firearm by ID: " ^ M.Error.to_string e)
   | Ok None -> fail "Firearm not found"
   | Ok (Some f) -> check string "firearm name" name f.M.Firearm.name);
  
  (* Update rounds *)
  (match M.FirearmRepo.update_rounds id 100 with
   | Error e -> fail ("Failed to update rounds: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Check rounds updated *)
  (match M.FirearmRepo.get_by_id id with
   | Ok (Some f) -> check int "rounds fired" 100 f.M.Firearm.rounds_fired
   | _ -> fail "Failed to verify rounds update");
  
  (* Delete firearm *)
  (match M.FirearmRepo.delete id with
   | Error e -> fail ("Failed to delete firearm: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Verify deletion *)
  (match M.FirearmRepo.get_by_id id with
   | Ok None -> ()  (* Success *)
   | Ok (Some _) -> fail "Firearm still exists after deletion"
   | Error e -> fail ("Error checking deletion: " ^ M.Error.to_string e))

let test_consumable_repository () =
  let name = random_name "TestAmmo" in
  let id = M.Id.generate () in
  
  let cons : M.Consumable.consumable = {
    M.Consumable.id = id;
    M.Consumable.name = name;
    M.Consumable.category = "ammunition";
    M.Consumable.unit = "rounds";
    M.Consumable.quantity = 500;
    M.Consumable.min_quantity = 100;
    M.Consumable.notes = Some "Test ammo";
    M.Consumable.purchase_price = Some 29.99;
    M.Consumable.created_at = M.Timestamp.now ();
    M.Consumable.updated_at = M.Timestamp.now ();
  } in
  
  (* Add consumable *)
  (match M.ConsumableRepo.add cons with
   | Error e -> fail ("Failed to add consumable: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get by ID - returns option *)
  (match M.ConsumableRepo.get_by_id id with
   | Error e -> fail ("Failed to get consumable: " ^ M.Error.to_string e)
   | Ok None -> fail "Consumable not found"
   | Ok (Some c) -> check int "quantity" 500 c.M.Consumable.quantity);
  
  (* Update quantity *)
  (match M.ConsumableRepo.update_quantity id 100 "ADD" (Some "Restock") with
   | Error e -> fail ("Failed to update quantity: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Verify quantity updated *)
  (match M.ConsumableRepo.get_by_id id with
   | Ok (Some c) -> check int "updated quantity" 600 c.M.Consumable.quantity
   | Error e -> fail ("Failed to verify quantity: " ^ M.Error.to_string e)
   | Ok None -> fail "Consumable not found");
  
  (* Check history *)
  (match M.ConsumableRepo.get_history id with
   | Error e -> fail ("Failed to get history: " ^ M.Error.to_string e)
   | Ok history -> check bool "has history" true (List.length history > 0));
  
  (* Delete *)
  (match M.ConsumableRepo.delete id with
   | Error e -> fail ("Failed to delete: " ^ M.Error.to_string e)
   | Ok () -> ())

let test_checkout_repository () =
  let name = random_name "TestBorrower" in
  let id = M.Id.generate () in
  
  let borrower : M.Checkout.borrower = {
    M.Checkout.id = id;
    M.Checkout.name = name;
    M.Checkout.phone = "555-1234";
    M.Checkout.email = "test@example.com";
    M.Checkout.notes = Some "Test borrower";
    M.Checkout.created_at = M.Timestamp.now ();
    M.Checkout.updated_at = M.Timestamp.now ();
  } in
  
  (* Add borrower *)
  (match M.CheckoutRepo.add_borrower borrower with
   | Error e -> fail ("Failed to add borrower: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get by name *)
  (match M.CheckoutRepo.get_borrower_by_name name with
   | Error e -> fail ("Failed to get borrower: " ^ M.Error.to_string e)
   | Ok None -> fail "Borrower not found"
   | Ok (Some b) -> check string "borrower name" name b.M.Checkout.name);
  
  (* Get all borrowers *)
  (match M.CheckoutRepo.get_all_borrowers () with
   | Error e -> fail ("Failed to get borrowers: " ^ M.Error.to_string e)
   | Ok borrowers ->
       let has_borrower = List.exists (fun (b : M.Checkout.borrower) -> 
         M.Id.equal b.M.Checkout.id id
       ) borrowers in
       check bool "borrower in list" true has_borrower)

let test_gear_repository () =
  let name = random_name "TestBackpack" in
  let now = M.Timestamp.now () in
  let id = M.Id.generate () in
  
  let gear : M.Gear.t = {
    M.Gear.id = id;
    M.Gear.name = name;
    M.Gear.category = "pack";
    M.Gear.brand = Some "TestBrand";
    M.Gear.purchase_date = now;
    M.Gear.notes = Some "Test gear";
    M.Gear.status = "AVAILABLE";
    M.Gear.created_at = now;
    M.Gear.updated_at = now;
  } in
  
  (* Add gear *)
  (match M.GearRepo.add_soft_gear gear with
   | Error e -> fail ("Failed to add gear: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get all *)
  (match M.GearRepo.get_all_soft_gear () with
   | Error e -> fail ("Failed to get gear: " ^ M.Error.to_string e)
   | Ok gears ->
       check bool "gear in list" true
         (List.exists (fun g -> M.Id.equal g.M.Gear.id id) gears));
  
  (* Update status *)
  (match M.GearRepo.update_soft_gear_status id "CHECKED_OUT" with
   | Error e -> fail ("Failed to update status: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Delete *)
  (match M.GearRepo.delete_soft_gear id with
   | Error e -> fail ("Failed to delete gear: " ^ M.Error.to_string e)
   | Ok () -> ())

let test_nfa_item_repository () =
  let name = random_name "TestSuppressor" in
  let now = M.Timestamp.now () in
  let id = M.Id.generate () in
  
  let nfa_item : M.Gear.nfa_item = {
    M.Gear.nfa_id = id;
    M.Gear.nfa_name = name;
    M.Gear.nfa_type = "SUPPRESSOR";
    M.Gear.manufacturer = Some "TestMfg";
    M.Gear.serial_number = Some "SN123";
    M.Gear.tax_stamp_id = "TX12345";
    M.Gear.caliber_bore = Some ".30";
    M.Gear.nfa_purchase_date = now;
    M.Gear.form_type = Some "Form 4";
    M.Gear.trust_name = Some "Test Trust";
    M.Gear.nfa_notes = Some "Test NFA item";
    M.Gear.nfa_status = "AVAILABLE";
    M.Gear.rounds_fired = 0;
    M.Gear.clean_interval_rounds = 1000;
    M.Gear.oil_interval_days = 180;
    M.Gear.needs_maintenance = false;
    M.Gear.maintenance_conditions = None;
    M.Gear.last_cleaned_at = None;
    M.Gear.last_oiled_at = None;
    M.Gear.nfa_created_at = now;
    M.Gear.nfa_updated_at = now;
  } in
  
  (* Add NFA item *)
  (match M.NFAItemRepo.add nfa_item with
   | Error e -> fail ("Failed to add NFA item: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get by ID - returns option *)
  (match M.NFAItemRepo.get_by_id id with
   | Error e -> fail ("Failed to get NFA item: " ^ M.Error.to_string e)
   | Ok None -> fail "NFA item not found"
   | Ok (Some item) -> check string "nfa name" name item.M.Gear.nfa_name);
  
  (* Update rounds *)
  (match M.NFAItemRepo.update_rounds_fired id 50 with
   | Error e -> fail ("Failed to update rounds: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Delete *)
  (match M.NFAItemRepo.delete id with
   | Error e -> fail ("Failed to delete NFA item: " ^ M.Error.to_string e)
   | Ok () -> ())

let test_reload_repository () =
  let id = M.Id.generate () in
  let now = M.Timestamp.now () in
  
  let batch : M.Reload.reload_batch = {
    M.Reload.id = id;
    M.Reload.cartridge = ".223 Rem";
    M.Reload.firearm_id = None;
    M.Reload.date_created = now;
    M.Reload.bullet_maker = "Hornady";
    M.Reload.bullet_model = "FMJ";
    M.Reload.bullet_weight_gr = Some 55;
    M.Reload.powder_name = "Varget";
    M.Reload.powder_charge_gr = Some 25.5;
    M.Reload.powder_lot = "LOT123";
    M.Reload.primer_maker = "CCI";
    M.Reload.primer_type = "BR4";
    M.Reload.case_brand = "LC";
    M.Reload.case_times_fired = Some 3;
    M.Reload.case_prep_notes = "Tumbled";
    M.Reload.coal_in = Some 2.26;
    M.Reload.crimp_style = "Light";
    M.Reload.test_date = None;
    M.Reload.avg_velocity = Some 2800;
    M.Reload.es = Some 25;
    M.Reload.sd = Some 8;
    M.Reload.group_size_inches = Some 0.75;
    M.Reload.group_distance_yards = Some 100;
    M.Reload.intended_use = "Plinking";
    M.Reload.status = "WORKUP";
    M.Reload.notes = Some "Test batch";
    M.Reload.created_at = now;
    M.Reload.updated_at = now;
  } in
  
  (* Add batch *)
  (match M.ReloadRepo.add_reload_batch batch with
   | Error e -> fail ("Failed to add batch: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get by ID *)
  (match M.ReloadRepo.get_reload_batch_by_id id with
   | Error e -> fail ("Failed to get batch: " ^ M.Error.to_string e)
   | Ok b -> check string "cartridge" ".223 Rem" b.M.Reload.cartridge);
  
  (* Update status *)
  (match M.ReloadRepo.update_reload_batch_status id "READY" with
   | Error e -> fail ("Failed to update status: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Delete *)
  (match M.ReloadRepo.delete_reload_batch id with
   | Error e -> fail ("Failed to delete batch: " ^ M.Error.to_string e)
   | Ok () -> ())

let test_loadout_repository () =
  let id = M.Id.generate () in
  let now = M.Timestamp.now () in
  
  let loadout : M.Loadout.loadout = {
    M.Loadout.id = id;
    M.Loadout.name = random_name "TestLoadout";
    M.Loadout.description = Some "Test description";
    M.Loadout.created_date = now;
    M.Loadout.notes = Some "Test notes";
    M.Loadout.updated_at = now;
  } in
  
  (* Add loadout *)
  (match M.LoadoutRepo.add_loadout loadout with
   | Error e -> fail ("Failed to add loadout: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get by ID *)
  (match M.LoadoutRepo.get_loadout_by_id id with
   | Error e -> fail ("Failed to get loadout: " ^ M.Error.to_string e)
   | Ok l -> check string "loadout name" loadout.M.Loadout.name l.M.Loadout.name);
  
  (* Add item to loadout - create loadout_item record *)
  let item_id = M.Id.generate () in
  let loadout_item : M.Loadout.loadout_item = {
    M.Loadout.id = M.Id.generate ();
    M.Loadout.loadout_id = id;
    M.Loadout.item_id = item_id;
    M.Loadout.item_type = "FIREARM";
    M.Loadout.notes = None;
  } in
  (match M.LoadoutRepo.add_loadout_item loadout_item with
   | Error e -> fail ("Failed to add item: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get items *)
  (match M.LoadoutRepo.get_loadout_items id with
   | Error e -> fail ("Failed to get items: " ^ M.Error.to_string e)
   | Ok items -> check bool "has items" true (List.length items > 0));
  
  (* Delete loadout *)
  (match M.LoadoutService.delete_loadout id with
   | Error e -> fail ("Failed to delete loadout: " ^ M.Error.to_string e)
   | Ok () -> ())

(* ============================================================================
   Service Tests
   ============================================================================ *)

let test_maintenance_service () =
  let item_id = M.Id.generate () in
  let item_type = "FIREARM" in
  
  (* Log various maintenance events *)
  (match M.MaintenanceService.log_cleaning item_id item_type () with
   | Error e -> fail ("Failed to log cleaning: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_fired_rounds item_id item_type 100 () with
   | Error e -> fail ("Failed to log fired rounds: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_lubrication item_id item_type () with
   | Error e -> fail ("Failed to log lubrication: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_oiling item_id item_type () with
   | Error e -> fail ("Failed to log oiling: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_repair item_id item_type () with
   | Error e -> fail ("Failed to log repair: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_inspection item_id item_type () with
   | Error e -> fail ("Failed to log inspection: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_hunting item_id item_type () with
   | Error e -> fail ("Failed to log hunting: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_zeroing item_id item_type 100 () with
   | Error e -> fail ("Failed to log zeroing: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_rain_exposure item_id item_type () with
   | Error e -> fail ("Failed to log rain exposure: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_corrosive_ammo item_id item_type "7.62x54r" () with
   | Error e -> fail ("Failed to log corrosive ammo: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (match M.MaintenanceService.log_lead_ammo item_id item_type () with
   | Error e -> fail ("Failed to log lead ammo: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Get maintenance history *)
  (match M.MaintenanceService.get_maintenance_history item_id item_type with
   | Error e -> fail ("Failed to get history: " ^ M.Error.to_string e)
   | Ok logs -> check bool "has logs" true (List.length logs > 0))

let test_loadout_service () =
  (* Create test loadout *)
  let loadout_id = M.Id.generate () in
  let loadout : M.Loadout.loadout = {
    M.Loadout.id = loadout_id;
    M.Loadout.name = random_name "ServiceTestLoadout";
    M.Loadout.description = None;
    M.Loadout.created_date = M.Timestamp.now ();
    M.Loadout.notes = None;
    M.Loadout.updated_at = M.Timestamp.now ();
  } in
  
  (match M.LoadoutRepo.add_loadout loadout with
   | Error e -> fail ("Failed to create loadout: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Validate checkout *)
  (match M.LoadoutService.validate_checkout loadout_id with
   | Error e -> fail ("Failed to validate: " ^ M.Error.to_string e)
   | Ok _result -> ());
  
  (* Cleanup *)
  (match M.LoadoutService.delete_loadout loadout_id with
   | Error _ -> ()  (* Ignore errors in cleanup *)
   | Ok () -> ())

let test_checkout_service () =
  (* Test item availability *)
  let item_id = M.Id.generate () in
  let _ = M.CheckoutService.is_item_available item_id "FIREARM" in
  
  (* Test maintenance status *)
  let _ = M.CheckoutService.check_maintenance_status item_id "FIREARM" in
  
  (* Test getting checkouts *)
  (match M.CheckoutService.get_active_checkouts () with
   | Error e -> fail ("Failed to get checkouts: " ^ M.Error.to_string e)
   | Ok _checkouts -> ());
  
  (match M.CheckoutService.get_checkout_history () with
   | Error e -> fail ("Failed to get history: " ^ M.Error.to_string e)
   | Ok _history -> ())

(* ============================================================================
   Import/Export Tests
   ============================================================================ *)

let test_csv_parsing () =
  (* Create test CSV file *)
  let test_path = "/tmp/test_parse.csv" in
  let chan = open_out test_path in
  output_string chan "; Test file\n";
  output_string chan "[SECTION1]\n";
  output_string chan "col1,col2,col3\n";
  output_string chan "a,b,c\n";
  output_string chan "d,e,f\n";
  output_string chan "[SECTION2]\n";
  output_string chan "x,y\n";
  output_string chan "1,2\n";
  close_out chan;
  
  (* Parse it *)
  let sections = M.ImportExport.parse_sectioned_csv test_path in
  check int "section count" 2 (List.length sections);
  
  (* Check section names *)
  let section_names = List.map fst sections in
  check bool "has SECTION1" true (List.mem "SECTION1" section_names);
  check bool "has SECTION2" true (List.mem "SECTION2" section_names);
  
  (* Cleanup *)
  Sys.remove test_path

let test_csv_escape () =
  (* Test escaping *)
  let test_cases = [
    ("simple", "simple");
    ("with,comma", "\"with,comma\"");
    ("with\"quote", "\"with\"\"quote\"");
    ("normal text", "normal text");
  ] in
  
  List.iter (fun (input, expected) ->
    let escaped = M.ImportExport.escape_csv_field input in
    check string ("escape: " ^ input) expected escaped
  ) test_cases

let test_export_options () =
  (* Test default options *)
  let opts = M.ImportExport.default_export_options in
  check bool "firearms default" true opts.M.ImportExport.include_firearms;
  check bool "gear default" true opts.M.ImportExport.include_gear;
  check bool "nfa default" true opts.M.ImportExport.include_nfa_items;
  
  (* Test that options can be modified *)
  let custom_opts = { opts with
    M.ImportExport.include_firearms = false;
    M.ImportExport.include_consumables = false;
  } in
  check bool "custom firearms" false custom_opts.M.ImportExport.include_firearms;
  check bool "custom consumables" false custom_opts.M.ImportExport.include_consumables;
  check bool "custom gear unchanged" true custom_opts.M.ImportExport.include_gear

let test_import_result () =
  (* Test result structure *)
  let stats : M.ImportExport.entity_stats = {
    M.ImportExport.total_rows = 10;
    M.ImportExport.imported = 5;
    M.ImportExport.skipped = 3;
    M.ImportExport.overwritten = 1;
    M.ImportExport.errors = 1;
  } in
  
  check int "total rows" 10 stats.M.ImportExport.total_rows;
  check int "imported" 5 stats.M.ImportExport.imported;
  check int "skipped" 3 stats.M.ImportExport.skipped;
  check int "overwritten" 1 stats.M.ImportExport.overwritten;
  check int "errors" 1 stats.M.ImportExport.errors

let test_import_duplicate_handling () =
  (* Test duplicate info structure *)
  let dup : M.ImportExport.duplicate_info = {
    M.ImportExport.entity_type = "firearm";
    M.ImportExport.id = 1L;
    M.ImportExport.name = "Test Rifle";
    M.ImportExport.existing_record = "Old record";
  } in
  
  check string "entity type" "firearm" dup.M.ImportExport.entity_type;
  check string "name" "Test Rifle" dup.M.ImportExport.name;
  
  (* Test actions *)
  let actions = [
    M.ImportExport.Skip;
    M.ImportExport.Overwrite;
    M.ImportExport.Import_as_new;
    M.ImportExport.Cancel;
  ] in
  check int "action count" 4 (List.length actions)

let test_export_import_roundtrip () =
  (* This is a larger integration test *)
  let export_path = "/tmp/test_roundtrip.csv" in
  
  (* Export current database *)
  let options = { M.ImportExport.default_export_options with
    M.ImportExport.include_firearms = true;
    M.ImportExport.include_gear = true;
    M.ImportExport.include_consumables = false;
    M.ImportExport.include_reload_batches = false;
    M.ImportExport.include_loadouts = false;
    M.ImportExport.include_checkouts = false;
    M.ImportExport.include_borrowers = false;
    M.ImportExport.include_transfers = false;
    M.ImportExport.include_maintenance_logs = false;
    M.ImportExport.include_nfa_items = false;
    M.ImportExport.include_attachments = false;
  } in
  
  (match M.ImportExport.export_all_to_csv ~path:export_path ~options () with
   | Error e -> fail ("Export failed: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Verify file exists and has content *)
  (try
     let stats = Unix.stat export_path in
     check bool "file exists" true (stats.Unix.st_size > 0)
   with _ -> fail "Export file not created");
  
  (* Test import (dry run) *)
  let on_duplicate _dup = M.ImportExport.Skip in
  (match M.ImportExport.import_all_from_csv ~path:export_path ~dry_run:true ~on_duplicate () with
   | Error e -> fail ("Import failed: " ^ M.Error.to_string e)
   | Ok result ->
       check bool "import success" true result.M.ImportExport.success;
       check bool "not cancelled" false result.M.ImportExport.cancelled);
  
  (* Cleanup *)
  (try Sys.remove export_path with _ -> ())

(* ============================================================================
   Integration Tests
   ============================================================================ *)

let test_full_workflow () =
  (* Create a firearm *)
  let firearm_id = M.Id.generate () in
  let now = M.Timestamp.now () in
  
  let firearm : M.Firearm.t = {
    M.Firearm.id = firearm_id;
    M.Firearm.name = random_name "WorkflowRifle";
    M.Firearm.caliber = "5.56mm";
    M.Firearm.serial_number = "WF12345";
    M.Firearm.purchase_date = now;
    M.Firearm.notes = Some "Test workflow";
    M.Firearm.status = "AVAILABLE";
    M.Firearm.is_nfa = false;
    M.Firearm.nfa_type = None;
    M.Firearm.tax_stamp_id = "";
    M.Firearm.form_type = "";
    M.Firearm.barrel_length = "16";
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
  
  (match M.FirearmRepo.add firearm with
   | Error e -> fail ("Failed to add firearm: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Log maintenance *)
  (match M.MaintenanceService.log_cleaning firearm_id "FIREARM" () with
   | Error e -> fail ("Failed to log cleaning: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Fire some rounds *)
  (match M.MaintenanceService.log_fired_rounds firearm_id "FIREARM" 200 () with
   | Error e -> fail ("Failed to log rounds: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Create a borrower *)
  let borrower_id = M.Id.generate () in
  let borrower : M.Checkout.borrower = {
    M.Checkout.id = borrower_id;
    M.Checkout.name = random_name "WorkflowBorrower";
    M.Checkout.phone = "555-WORK";
    M.Checkout.email = "workflow@test.com";
    M.Checkout.notes = None;
    M.Checkout.created_at = now;
    M.Checkout.updated_at = now;
  } in
  
  (match M.CheckoutRepo.add_borrower borrower with
   | Error e -> fail ("Failed to add borrower: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Create a loadout *)
  let loadout_id = M.Id.generate () in
  let loadout : M.Loadout.loadout = {
    M.Loadout.id = loadout_id;
    M.Loadout.name = random_name "WorkflowLoadout";
    M.Loadout.description = Some "Test loadout";
    M.Loadout.created_date = now;
    M.Loadout.notes = None;
    M.Loadout.updated_at = now;
  } in
  
  (match M.LoadoutRepo.add_loadout loadout with
   | Error e -> fail ("Failed to add loadout: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Add firearm to loadout *)
  let loadout_item : M.Loadout.loadout_item = {
    M.Loadout.id = M.Id.generate ();
    M.Loadout.loadout_id = loadout_id;
    M.Loadout.item_id = firearm_id;
    M.Loadout.item_type = "FIREARM";
    M.Loadout.notes = None;
  } in
  (match M.LoadoutRepo.add_loadout_item loadout_item with
   | Error e -> fail ("Failed to add to loadout: " ^ M.Error.to_string e)
   | Ok () -> ());
  
  (* Validate checkout *)
  (match M.LoadoutService.validate_checkout loadout_id with
   | Error e -> fail ("Failed to validate: " ^ M.Error.to_string e)
   | Ok _ -> ());
  
  (* Cleanup *)
  (match M.LoadoutService.delete_loadout loadout_id with
   | Error _ -> ()
   | Ok () -> ());
  
  (match M.CheckoutRepo.delete_borrower borrower_id with
   | Error _ -> ()
   | Ok () -> ());
  
  (match M.FirearmRepo.delete firearm_id with
   | Error _ -> ()
   | Ok () -> ())

(* ============================================================================
   Test Runner
   ============================================================================ *)

let () =
  Random.self_init ();
  
  run "gearTracker-ml" [
    (* Core type tests *)
    "Core Types", [
      test_case "id operations" `Quick (with_test_db test_id_operations);
      test_case "timestamp operations" `Quick (with_test_db test_timestamp_operations);
      test_case "error types" `Quick test_error_types;
    ];
    
    (* Repository tests *)
    "Firearm Repository", [
      test_case "crud operations" `Quick (with_test_db test_firearm_repository);
    ];
    
    "Consumable Repository", [
      test_case "crud operations" `Quick (with_test_db test_consumable_repository);
    ];
    
    "Checkout Repository", [
      test_case "borrower operations" `Quick (with_test_db test_checkout_repository);
    ];
    
    "Gear Repository", [
      test_case "crud operations" `Quick (with_test_db test_gear_repository);
    ];
    
    "NFA Item Repository", [
      test_case "crud operations" `Quick (with_test_db test_nfa_item_repository);
    ];
    
    "Reload Repository", [
      test_case "crud operations" `Quick (with_test_db test_reload_repository);
    ];
    
    "Loadout Repository", [
      test_case "crud operations" `Quick (with_test_db test_loadout_repository);
    ];
    
    (* Service tests *)
    "Maintenance Service", [
      test_case "log all types" `Quick (with_test_db test_maintenance_service);
    ];
    
    "Loadout Service", [
      test_case "validate and manage" `Quick (with_test_db test_loadout_service);
    ];
    
    "Checkout Service", [
      test_case "availability and status" `Quick (with_test_db test_checkout_service);
    ];
    
    (* Import/Export tests *)
    "Import/Export", [
      test_case "csv parsing" `Quick test_csv_parsing;
      test_case "csv escaping" `Quick test_csv_escape;
      test_case "export options" `Quick test_export_options;
      test_case "import result" `Quick test_import_result;
      test_case "duplicate handling" `Quick test_import_duplicate_handling;
      test_case "export import roundtrip" `Quick (with_test_db test_export_import_roundtrip);
    ];
    
    (* Integration tests *)
    "Integration", [
      test_case "full workflow" `Quick (with_test_db test_full_workflow);
    ];
  ]
