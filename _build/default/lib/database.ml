(* gearTracker_ml - Database connection and schema *)

type db = Sqlite3.db

let db_path = ref (Filename.concat (Sys.getenv "HOME") ".gear_tracker/tracker.db")

let set_db_path path = db_path := path

let get_db_path () = !db_path

let open_db ?(readonly=false) () =
  if readonly then
    Sqlite3.db_open ~mode:`READONLY !db_path
  else
    Sqlite3.db_open !db_path

let close_db db = ignore (Sqlite3.db_close db)

let db_exists () = Sys.file_exists !db_path

let schema_sql = {|
CREATE TABLE IF NOT EXISTS firearms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    caliber TEXT NOT NULL,
    serial_number TEXT UNIQUE,
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
    last_cleaned_at INTEGER,
    last_oiled_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

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

CREATE TABLE IF NOT EXISTS nfa_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    nfa_type TEXT NOT NULL,
    manufacturer TEXT,
    serial_number TEXT,
    tax_stamp_id NOT NULL,
    caliber_bore TEXT,
    purchase_date INTEGER NOT NULL,
    form_type TEXT,
    trust_name TEXT,
    notes TEXT,
    status TEXT DEFAULT 'AVAILABLE',
    rounds_fired INTEGER DEFAULT 0,
    clean_interval_rounds INTEGER DEFAULT 500,
    oil_interval_days INTEGER DEFAULT 90,
    needs_maintenance INTEGER DEFAULT 0,
    maintenance_conditions TEXT DEFAULT '',
    last_cleaned_at INTEGER,
    last_oiled_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    serial_number TEXT,
    purchase_date INTEGER,
    mounted_on_firearm_id INTEGER,
    mount_position TEXT,
    zero_distance_yards INTEGER,
    zero_notes TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

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

CREATE TABLE IF NOT EXISTS consumable_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    consumable_id INTEGER NOT NULL,
    transaction_type TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    date INTEGER NOT NULL,
    notes TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    item_type TEXT NOT NULL,
    log_type TEXT NOT NULL,
    date INTEGER NOT NULL,
    details TEXT,
    ammo_count INTEGER,
    photo_path TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS borrowers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    phone TEXT,
    email TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS checkouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    item_type TEXT NOT NULL,
    borrower_id INTEGER NOT NULL,
    checkout_date INTEGER NOT NULL,
    expected_return INTEGER,
    actual_return INTEGER,
    notes TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    firearm_id INTEGER NOT NULL,
    transfer_date INTEGER NOT NULL,
    buyer_name TEXT NOT NULL,
    buyer_address TEXT NOT NULL,
    buyer_dl_number TEXT NOT NULL,
    buyer_ltc_number TEXT,
    sale_price REAL,
    ffl_dealer TEXT,
    ffl_license TEXT,
    notes TEXT,
    created_at INTEGER NOT NULL
);

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

CREATE TABLE IF NOT EXISTS loadouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_date INTEGER NOT NULL,
    notes TEXT,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS loadout_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    loadout_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    item_type TEXT NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS loadout_consumables (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    loadout_id INTEGER NOT NULL,
    consumable_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS loadout_checkouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    loadout_id INTEGER NOT NULL,
    checkout_id INTEGER NOT NULL,
    return_date INTEGER,
    rounds_fired INTEGER DEFAULT 0,
    rain_exposure INTEGER DEFAULT 0,
    ammo_type TEXT,
    notes TEXT
);
|}

let init_schema db =
  let stmt = Sqlite3.prepare db schema_sql in
  ignore (Sqlite3.step stmt);
  Sqlite3.finalize stmt

let migrate_columns db =
  let ignore_result _ = () in
  ignore_result (try Sqlite3.exec db "ALTER TABLE firearms ADD COLUMN last_cleaned_at INTEGER" with _ -> Sqlite3.Rc.OK);
  ignore_result (try Sqlite3.exec db "ALTER TABLE firearms ADD COLUMN last_oiled_at INTEGER" with _ -> Sqlite3.Rc.OK);
  ignore_result (try Sqlite3.exec db "ALTER TABLE nfa_items ADD COLUMN last_cleaned_at INTEGER" with _ -> Sqlite3.Rc.OK);
  ignore_result (try Sqlite3.exec db "ALTER TABLE nfa_items ADD COLUMN last_oiled_at INTEGER" with _ -> Sqlite3.Rc.OK)

let transaction db f =
  ignore (Sqlite3.exec db "BEGIN TRANSACTION");
  try
    let result = f db in
    ignore (Sqlite3.exec db "COMMIT");
    Ok result
  with e ->
    ignore (Sqlite3.exec db "ROLLBACK");
    Error (Printexc.to_string e)

let last_insert_rowid db = Sqlite3.last_insert_rowid db
