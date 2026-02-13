(* GearTracker ML - Direct SQLite Test Script *)

let () =
  print_endline "==========================================";
  print_endline "  GearTracker ML - SQLite Direct Test";
  print_endline "==========================================";
  print_endline "";

  (* Set database path *)
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/test_tracker.db" in
  print_endline (Printf.sprintf "Database path: %s" db_path);

  (* Create parent directory if needed *)
  (try Unix.mkdir (Filename.dirname db_path) 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ());

  (* Open database *)
  let db = Sqlite3.db_open db_path in
  print_endline "Database opened successfully.";
  print_endline "";

  (* Create tables *)
  print_endline "Creating schema...";

  let create_table sql name =
    match Sqlite3.exec db sql with
    | Sqlite3.Rc.OK -> print_endline (Printf.sprintf "  Created: %s" name)
    | _ -> print_endline (Printf.sprintf "  Error creating %s: %s" name (Sqlite3.errmsg db))
  in

  create_table {|
    CREATE TABLE IF NOT EXISTS firearms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        caliber TEXT NOT NULL,
        serial_number TEXT,
        purchase_date INTEGER NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'AVAILABLE',
        is_nfa INTEGER DEFAULT 0,
        nfa_type TEXT,
        tax_stamp_id TEXT DEFAULT '',
        form_type TEXT DEFAULT '',
        barrel_length TEXT DEFAULT '',
        trust_name TEXT DEFAULT '',
        transfer_status TEXT DEFAULT 'OWNED',
        rounds_fired INTEGER DEFAULT 0,
        clean_interval_rounds INTEGER DEFAULT 500,
        oil_interval_days INTEGER DEFAULT 90,
        needs_maintenance INTEGER DEFAULT 0,
        maintenance_conditions TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
  |} "firearms table";

  create_table {|
    CREATE TABLE IF NOT EXISTS soft_gear (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        purchase_date INTEGER NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'AVAILABLE',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
  |} "soft_gear table";

  create_table {|
    CREATE TABLE IF NOT EXISTS consumables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_quantity INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        purchase_price REAL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
  |} "consumables table";

  create_table {|
    CREATE TABLE IF NOT EXISTS borrowers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        email TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
  |} "borrowers table";

  create_table {|
    CREATE TABLE IF NOT EXISTS reload_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cartridge TEXT NOT NULL,
        firearm_id INTEGER,
        date_created INTEGER NOT NULL,
        bullet_maker TEXT,
        bullet_model TEXT,
        bullet_weight_gr INTEGER,
        powder_name TEXT,
        powder_charge_gr REAL,
        powder_lot TEXT,
        primer_maker TEXT,
        primer_type TEXT,
        case_brand TEXT,
        case_times_fired INTEGER,
        case_prep_notes TEXT,
        coal_in REAL,
        crimp_style TEXT,
        test_date INTEGER,
        avg_velocity INTEGER,
        es INTEGER,
        sd INTEGER,
        group_size_inches REAL,
        group_distance_yards INTEGER,
        intended_use TEXT,
        status TEXT DEFAULT 'WORKUP',
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
  |} "reload_batches table";

  print_endline "";

  (* Insert sample firearms *)
  print_endline "Inserting sample firearms...";
  let now = Unix.gettimeofday () |> Int64.of_float in
  let one_year_ago = Int64.sub now (Int64.of_int (365 * 24 * 60 * 60)) in
  let six_months_ago = Int64.sub now (Int64.of_int (180 * 24 * 60 * 60)) in
  let two_years_ago = Int64.sub now (Int64.of_int (730 * 24 * 60 * 60)) in

  let insert_firearm name caliber serial notes is_nfa nfa_type tax_stamp purchase_date =
    let sql = Printf.sprintf
        {|INSERT INTO firearms (name, caliber, serial_number, notes, is_nfa, nfa_type, tax_stamp_id, purchase_date, created_at, updated_at)
          VALUES ('%s', '%s', '%s', '%s', %d, '%s', '%s', %Ld, %Ld, %Ld)|}
        name caliber serial notes (if is_nfa then 1 else 0)
        (Option.value ~default:"" nfa_type) (Option.value ~default:"" tax_stamp) purchase_date now now
    in
    match Sqlite3.exec db sql with
    | Sqlite3.Rc.OK -> print_endline (Printf.sprintf "  Added: %s" name)
    | _ -> print_endline (Printf.sprintf "  Error: %s" (Sqlite3.errmsg db))
  in

  insert_firearm "AR-15 Competition" "5.56mm" "SN-2024-001" "Primary competition rifle" false None None one_year_ago;
  insert_firearm "AR-15 SBR" "5.56mm" "SN-2024-002" "Home defense SBR" true (Some "SBR") (Some "TAX-2024-0156") six_months_ago;
  insert_firearm "Glock 19" "9mm" "SN-2023-887" "Carry pistol" false None None two_years_ago;

  print_endline "";

  (* Insert sample gear *)
  print_endline "Inserting sample gear...";
  let insert_gear name category brand notes =
    let sql = Printf.sprintf
        {|INSERT INTO soft_gear (name, category, brand, notes, purchase_date, status, created_at, updated_at)
          VALUES ('%s', '%s', '%s', '%s', %Ld, 'AVAILABLE', %Ld, %Ld)|}
        name category brand notes one_year_ago now now
    in
    match Sqlite3.exec db sql with
    | Sqlite3.Rc.OK -> print_endline (Printf.sprintf "  Added: %s - %s" name category)
    | _ -> print_endline (Printf.sprintf "  Error: %s" (Sqlite3.errmsg db))
  in

  insert_gear "Nano Puff Jacket" "Clothing" "Patagonia" "Winter hunting jacket";
  insert_gear "JPC 2.0" "Armor" "Crye Precision" "Plate carrier with cummerbund";
  insert_gear "Mechanix Gloves" "Clothing" "Mechanix" "Shooting gloves";

  print_endline "";

  (* Insert sample consumables *)
  print_endline "Inserting sample consumables...";
  let insert_consumable name category unit quantity min_qty notes =
    let sql = Printf.sprintf
        {|INSERT INTO consumables (name, category, unit, quantity, min_quantity, notes, created_at, updated_at)
          VALUES ('%s', '%s', '%s', %d, %d, '%s', %Ld, %Ld)|}
        name category unit quantity min_qty notes now now
    in
    match Sqlite3.exec db sql with
    | Sqlite3.Rc.OK -> print_endline (Printf.sprintf "  Added: %s (%d %s)" name quantity unit)
    | _ -> print_endline (Printf.sprintf "  Error: %s" (Sqlite3.errmsg db))
  in

  insert_consumable "9mm 115gr FMJ" "Ammo" "round" 500 100 "Training ammo";
  insert_consumable "9mm 124gr HST" "Ammo" "round" 200 50 "Self defense ammo";
  insert_consumable "Ballistol" "Cleaning" "oz" 16 5 "Multi-purpose lubricant";
  insert_consumable "Snap Caps" "Training" "each" 10 2 "For dry fire practice";

  print_endline "";

  (* Insert sample borrower *)
  print_endline "Inserting sample borrower...";
  let sql = Printf.sprintf
      {|INSERT INTO borrowers (name, phone, email, notes, created_at, updated_at)
        VALUES ('%s', '%s', '%s', '%s', %Ld, %Ld)|}
      "John Smith" "555-0123" "john.shooter@example.com" "Local shooting buddy" now now
  in
  (match Sqlite3.exec db sql with
   | Sqlite3.Rc.OK -> print_endline "  Added: John Smith"
   | _ -> print_endline (Printf.sprintf "  Error: %s" (Sqlite3.errmsg db)));

  print_endline "";

  (* Insert sample reload batch *)
  print_endline "Inserting sample reload batch...";
  let sql = Printf.sprintf
      {|INSERT INTO reload_batches (cartridge, date_created, bullet_maker, bullet_model, bullet_weight_gr, powder_name,
        powder_charge_gr, powder_lot, primer_maker, primer_type, case_brand, case_times_fired,
        coal_in, intended_use, status, created_at, updated_at)
        VALUES ('%s', %Ld, '%s', '%s', %d, '%s', %.1f, '%s', '%s', '%s', '%s', %d, %.3f, '%s', '%s', %Ld, %Ld)|}
      "9mm 124gr" now "Hornady" "American Gunner" 124 "CFE223" 22.5 "LOT-2024-001" "CCI" "Small Pistol"
      "Lake City" 2 1.125 "Competition" "TESTED" now now
  in
  (match Sqlite3.exec db sql with
   | Sqlite3.Rc.OK -> print_endline "  Added: 9mm 124gr Hornady reload"
   | _ -> print_endline (Printf.sprintf "  Error: %s" (Sqlite3.errmsg db)));

  print_endline "";

  (* Query and display all firearms *)
  print_endline "==========================================";
  print_endline "  Querying Data";
  print_endline "==========================================";
  print_endline "";

  print_endline "Firearms:";
  let stmt = Sqlite3.prepare db "SELECT id, name, caliber, serial_number, status FROM firearms ORDER BY name" in
  let rec print_rows () =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | Sqlite3.Rc.ROW ->
      let id = Sqlite3.column_int stmt 0 in
      let name = Sqlite3.column_text stmt 1 in
      let caliber = Sqlite3.column_text stmt 2 in
      let serial = Sqlite3.column_text stmt 3 in
      let status = Sqlite3.column_text stmt 4 in
      print_endline (Printf.sprintf "  [%d] %s - %s (%s) - %s" id name caliber serial status);
      print_rows ()
    | _ ->
      print_endline (Printf.sprintf "  Error querying: %s" (Sqlite3.errmsg db))
  in
  print_rows ();
  ignore (Sqlite3.finalize stmt);

  print_endline "";

  print_endline "Consumables:";
  let stmt = Sqlite3.prepare db "SELECT id, name, category, quantity, unit FROM consumables ORDER BY category, name" in
  let rec print_rows () =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | Sqlite3.Rc.ROW ->
      let id = Sqlite3.column_int stmt 0 in
      let name = Sqlite3.column_text stmt 1 in
      let category = Sqlite3.column_text stmt 2 in
      let qty = Sqlite3.column_int stmt 3 in
      let unit = Sqlite3.column_text stmt 4 in
      print_endline (Printf.sprintf "  [%d] %s - %s: %d %s" id name category qty unit);
      print_rows ()
    | _ ->
      print_endline (Printf.sprintf "  Error querying: %s" (Sqlite3.errmsg db))
  in
  print_rows ();
  ignore (Sqlite3.finalize stmt);

  print_endline "";

  print_endline "Borrowers:";
  let stmt = Sqlite3.prepare db "SELECT id, name, phone FROM borrowers ORDER BY name" in
  let rec print_rows () =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | Sqlite3.Rc.ROW ->
      let id = Sqlite3.column_int stmt 0 in
      let name = Sqlite3.column_text stmt 1 in
      let phone = Sqlite3.column_text stmt 2 in
      print_endline (Printf.sprintf "  [%d] %s (%s)" id name phone);
      print_rows ()
    | _ ->
      print_endline (Printf.sprintf "  Error querying: %s" (Sqlite3.errmsg db))
  in
   print_rows ();
   ignore (Sqlite3.finalize stmt);

  print_endline "";

  print_endline "Reload Batches:";
  let stmt = Sqlite3.prepare db "SELECT id, cartridge, bullet_maker, bullet_model, status FROM reload_batches ORDER BY id" in
  let rec print_rows () =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | Sqlite3.Rc.ROW ->
      let id = Sqlite3.column_int stmt 0 in
      let cartridge = Sqlite3.column_text stmt 1 in
      let bullet_maker = Sqlite3.column_text stmt 2 in
      let bullet_model = Sqlite3.column_text stmt 3 in
      let status = Sqlite3.column_text stmt 4 in
      print_endline (Printf.sprintf "  [%d] %s - %s %s (%s)" id cartridge bullet_maker bullet_model status);
      print_rows ()
    | _ ->
      print_endline (Printf.sprintf "  Error querying: %s" (Sqlite3.errmsg db))
  in
  print_rows ();
  ignore (Sqlite3.finalize stmt);

  (* Close database *)
  ignore (Sqlite3.db_close db);

  print_endline "";
  print_endline "==========================================";
  print_endline "  Test Complete!";
  print_endline (Printf.sprintf "Database created at: %s" db_path);
  print_endline "=========================================="
