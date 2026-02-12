(* GearTracker ML - CLI Interface *)

open GearTracker_ml

let print_header () =
  print_endline "==========================================";
  print_endline "  GearTracker ML - Firearms & Gear Manager";
  print_endline "";
  print_endline "========================================="

let format_timestamp ts =
  let open Unix in
  let tm = localtime (Timestamp.to_float ts) in
  Printf.sprintf "%04d-%02d-%02d" (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday

let prompt_string ?(default="") prompt =
  print_string prompt;
  flush stdout;
  let input = read_line () in
  if input = "" then default else input

let prompt_int ?(default=0) prompt =
  print_string prompt;
  flush stdout;
  try int_of_string (read_line ()) with _ -> default

let prompt_float ?(default=0.0) prompt =
  print_string prompt;
  flush stdout;
  try float_of_string (read_line ()) with _ -> default

let prompt_bool prompt =
  print_string prompt;
  flush stdout;
  let input = String.lowercase_ascii (read_line ()) in
  input = "y" || input = "yes" || input = "true"

let prompt_optional prompt =
  print_string prompt;
  flush stdout;
  let input = read_line () in
  if input = "" then None else Some input

let rec main_loop () =
  print_endline "";
  print_endline "Commands:";
  print_endline "  lf  - List firearms";
  print_endline "  af  - Add firearm";
  print_endline "  df  - Delete firearm";
  print_endline "  lg  - List gear";
  print_endline "  ag  - Add gear item";
  print_endline "  dg  - Delete gear";
  print_endline "  lc  - List consumables";
  print_endline "  ac  - Add consumable";
  print_endline "  dc  - Delete consumable";
  print_endline "  lr  - List reload batches";
  print_endline "  ar  - Add reload batch";
  print_endline "  dr  - Delete reload batch";
  print_endline "  lb  - List borrowers";
  print_endline "  ab  - Add borrower";
  print_endline "  db  - Delete borrower";
  print_endline "  co  - Checkout item";
  print_endline "  rt  - Return item";
  print_endline "  lo  - List loadouts";
  print_endline "  ao  - Add loadout";
  print_endline "  do  - Delete loadout";
  print_endline "  ma  - Items needing maintenance";
  print_endline "  loq - Low stock consumables";
  print_endline "  help - Show this menu";
  print_endline "  quit - Exit application";
  print_endline "";

  print_string "> ";
  flush stdout;
  match String.trim (read_line ()) with
  | "quit" | "q" | "exit" ->
    print_endline "Goodbye!";
    ()
  | "help" | "h" | "" ->
    main_loop ()
  | "lf" | "list-firearms" | "list firearms" ->
    list_firearms ();
    main_loop ()
  | "af" | "add-firearm" | "add firearm" ->
    add_firearm ();
    main_loop ()
  | "df" | "delete-firearm" | "delete firearm" ->
    delete_firearm ();
    main_loop ()
  | "lg" | "list-gear" | "list gear" ->
    list_gear ();
    main_loop ()
  | "ag" | "add-gear" | "add gear" ->
    add_gear ();
    main_loop ()
  | "dg" | "delete-gear" | "delete gear" ->
    delete_gear ();
    main_loop ()
  | "lc" | "list-consumables" | "list consumables" ->
    list_consumables ();
    main_loop ()
  | "ac" | "add-consumable" | "add consumable" ->
    add_consumable ();
    main_loop ()
  | "dc" | "delete-consumable" | "delete consumable" ->
    delete_consumable ();
    main_loop ()
  | "lr" | "list-reloads" | "list reloads" ->
    list_reloads ();
    main_loop ()
  | "ar" | "add-reload" | "add reload" ->
    add_reload ();
    main_loop ()
  | "dr" | "delete-reload" | "delete reload" ->
    delete_reload ();
    main_loop ()
  | "lb" | "list-borrowers" | "list borrowers" ->
    list_borrowers ();
    main_loop ()
  | "ab" | "add-borrower" | "add borrower" ->
    add_borrower ();
    main_loop ()
  | "db" | "delete-borrower" | "delete borrower" ->
    delete_borrower ();
    main_loop ()
  | "co" | "checkout" ->
    checkout_item ();
    main_loop ()
  | "rt" | "return" ->
    return_item ();
    main_loop ()
  | "lo" | "list-loadouts" | "list loadouts" ->
    list_loadouts ();
    main_loop ()
  | "ao" | "add-loadout" | "add loadout" ->
    add_loadout ();
    main_loop ()
  | "do" | "delete-loadout" | "delete loadout" ->
    delete_loadout ();
    main_loop ()
  | "ma" | "maintenance" ->
    list_maintenance ();
    main_loop ()
  | "loq" | "low-stock" ->
    list_low_stock ();
    main_loop ()
  | cmd ->
    print_endline ("Unknown command: " ^ cmd);
    main_loop ()

and list_firearms () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Firearms";
  print_endline "==========================================";
  match GearTracker_ml.FirearmRepo.get_all () with
  | Ok firearms ->
    if firearms = [] then
      print_endline "No firearms found."
    else
      print_endline (Printf.sprintf "Found %d firearms:" (List.length firearms));
      print_endline "";
       List.iter (fun (f : GearTracker_ml.Firearm.t) ->
         let nfa_tag = if f.is_nfa then Printf.sprintf " (NFA - %s)" (Option.value ~default:"" f.nfa_type) else "" in
         print_endline (Printf.sprintf "[%s] %s%s" (GearTracker_ml.Id.to_string f.id) f.name nfa_tag);
         print_endline (Printf.sprintf "     Caliber: %s | SN: %s" f.caliber f.serial_number);
         print_endline (Printf.sprintf "     Status: %s | Rounds: %d" f.status f.rounds_fired);
         (match f.notes with Some n -> print_endline (Printf.sprintf "     Notes: %s" n) | None -> ());
         print_endline ""
       ) firearms
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_firearm () =
  print_endline "";
  print_endline "=== Add New Firearm ===";
  let name = prompt_string "Name: " in
  let caliber = prompt_string "Caliber: " in
  let serial = prompt_string "Serial Number: " in
  let notes = prompt_optional "Notes (optional): " in
  let is_nfa = prompt_bool "Is this an NFA item? (y/N): " in

  let nfa_type, tax_stamp_id, form_type, barrel_length, trust_name =
    if is_nfa then
      let nfa_type = prompt_string "NFA Type (SBR, SBS, Suppressor, AOW, DD): " in
      let tax_stamp = prompt_string "Tax Stamp ID: " in
      let form_type = prompt_string "Form Type (1/4): " in
      let barrel = prompt_string "Barrel Length: " in
      let trust = prompt_string "Trust Name: " in
      Some nfa_type, tax_stamp, form_type, barrel, trust
    else
      None, "", "", "", ""
  in

  let purchase_date = GearTracker_ml.Timestamp.now () in

  let firearm = GearTracker_ml.Firearm.create
      ~notes
      ~is_nfa
      ~nfa_type
      ~tax_stamp_id
      ~form_type
      ~barrel_length
      ~trust_name
      (GearTracker_ml.Id.generate ())
      name
      caliber
      serial
      purchase_date
  in

  match GearTracker_ml.FirearmRepo.add firearm with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Firearm added successfully! ID: %s" (GearTracker_ml.Id.to_string firearm.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding firearm: %s" (GearTracker_ml.Error.to_string e))

and delete_firearm () =
  print_endline "";
  print_endline "=== Delete Firearm ===";
  let id_str = prompt_string "Firearm ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.FirearmRepo.delete id with
    | Ok () -> print_endline "Firearm deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_gear () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Gear Items";
  print_endline "==========================================";
  match GearTracker_ml.GearRepo.get_all_soft_gear () with
  | Ok gear ->
    if gear = [] then
      print_endline "No gear items found."
    else
      print_endline (Printf.sprintf "Found %d gear items:" (List.length gear));
      print_endline "";
       List.iter (fun (g : GearTracker_ml.Gear.t) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string g.id) g.name);
         print_endline (Printf.sprintf "     Category: %s | Brand: %s" g.category (Option.value ~default:"-" g.brand));
         print_endline (Printf.sprintf "     Status: %s" g.status);
         (match g.notes with Some n -> print_endline (Printf.sprintf "     Notes: %s" n) | None -> ());
         print_endline ""
       ) gear
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_gear () =
  print_endline "";
  print_endline "=== Add Gear Item ===";
  let name = prompt_string "Name: " in
  let category = prompt_string "Category (Clothing, Armor, Eye Protection, Ear Protection, etc.): " in
  let brand = prompt_optional "Brand (optional): " in
  let notes = prompt_optional "Notes (optional): " in
  let purchase_date = GearTracker_ml.Timestamp.now () in

  let gear = GearTracker_ml.Gear.create
      ~brand
      ~notes
      (GearTracker_ml.Id.generate ())
      name
      category
      purchase_date
  in

  match GearTracker_ml.GearRepo.add_soft_gear gear with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Gear item added successfully! ID: %s" (GearTracker_ml.Id.to_string gear.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding gear: %s" (GearTracker_ml.Error.to_string e))

and delete_gear () =
  print_endline "";
  print_endline "=== Delete Gear Item ===";
  let id_str = prompt_string "Gear ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.GearRepo.delete_soft_gear id with
    | Ok () -> print_endline "Gear item deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_consumables () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Consumables";
  print_endline "==========================================";
  match GearTracker_ml.ConsumableRepo.get_all () with
  | Ok consumables ->
    if consumables = [] then
      print_endline "No consumables found."
    else
      print_endline (Printf.sprintf "Found %d consumables:" (List.length consumables));
      print_endline "";
       List.iter (fun (c : GearTracker_ml.Consumable.consumable) ->
         let low_stock = if c.quantity <= c.min_quantity then " [LOW STOCK]" else "" in
         print_endline (Printf.sprintf "[%s] %s%s" (GearTracker_ml.Id.to_string c.id) c.name low_stock);
         print_endline (Printf.sprintf "     Category: %s | Qty: %d %s" c.category c.quantity c.unit);
         print_endline (Printf.sprintf "     Min Qty: %d" c.min_quantity);
         (match c.notes with Some n -> print_endline (Printf.sprintf "     Notes: %s" n) | None -> ());
         print_endline ""
       ) consumables
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_consumable () =
  print_endline "";
  print_endline "=== Add Consumable ===";
  let name = prompt_string "Name: " in
  let category = prompt_string "Category (Ammo, Cleaning, etc.): " in
  let unit = prompt_string "Unit (round, oz, box, etc.): " in
  let quantity = prompt_int ~default:0 "Initial Quantity: " in
  let min_qty = prompt_int ~default:0 "Minimum Quantity: " in
  let notes = prompt_optional "Notes (optional): " in

  let consumable = GearTracker_ml.Consumable.create_consumable
      ~notes
      ~quantity
      ~min_quantity:min_qty
      (GearTracker_ml.Id.generate ())
      name
      category
      unit
  in

  match GearTracker_ml.ConsumableRepo.add consumable with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Consumable added successfully! ID: %s" (GearTracker_ml.Id.to_string consumable.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding consumable: %s" (GearTracker_ml.Error.to_string e))

and delete_consumable () =
  print_endline "";
  print_endline "=== Delete Consumable ===";
  let id_str = prompt_string "Consumable ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.ConsumableRepo.delete id with
    | Ok () -> print_endline "Consumable deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_reloads () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Reload Batches";
  print_endline "==========================================";
  match GearTracker_ml.ReloadRepo.get_all_reload_batches () with
  | Ok reloads ->
    if reloads = [] then
      print_endline "No reload batches found."
    else
      print_endline (Printf.sprintf "Found %d reload batches:" (List.length reloads));
      print_endline "";
       List.iter (fun (r : GearTracker_ml.Reload.reload_batch) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string r.id) r.cartridge);
         print_endline (Printf.sprintf "     Bullet: %s %s %s gr"
           r.bullet_maker r.bullet_model (match r.bullet_weight_gr with Some w -> string_of_int w | None -> "-"));
         print_endline (Printf.sprintf "     Powder: %s @ %.1f gr" r.powder_name (Option.value ~default:0.0 r.powder_charge_gr));
         print_endline (Printf.sprintf "     Primer: %s %s" r.primer_maker r.primer_type);
         print_endline (Printf.sprintf "     Status: %s" r.status);
         print_endline (Printf.sprintf "     Created: %s" (format_timestamp r.date_created));
         (match r.notes with Some n -> print_endline (Printf.sprintf "     Notes: %s" n) | None -> ());
         print_endline ""
       ) reloads
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_reload () =
  print_endline "";
  print_endline "=== Add Reload Batch ===";
  let cartridge = prompt_string "Cartridge (e.g., 9mm 124gr): " in
  let bullet_maker = prompt_string "Bullet Maker: " in
  let bullet_model = prompt_string "Bullet Model: " in
  let bullet_weight = prompt_int ~default:0 "Bullet Weight (gr): " in
  let powder_name = prompt_string "Powder Name: " in
  let powder_charge = prompt_float ~default:0.0 "Powder Charge (gr): " in
  let powder_lot = prompt_string "Powder Lot: " in
  let primer_maker = prompt_string "Primer Maker: " in
  let primer_type = prompt_string "Primer Type: " in
  let case_brand = prompt_string "Case Brand: " in
  let case_times = prompt_int ~default:0 "Case Times Fired: " in
  let coal = prompt_float ~default:0.0 "COAL (inches): " in
  let intended_use = prompt_string "Intended Use: " in
  let notes = prompt_optional "Notes (optional): " in
  let date_created = GearTracker_ml.Timestamp.now () in

  let batch = GearTracker_ml.Reload.create_reload_batch
      ~bullet_maker
      ~bullet_model
      ~bullet_weight_gr:(if bullet_weight > 0 then Some bullet_weight else None)
      ~powder_name
      ~powder_charge_gr:(if powder_charge > 0.0 then Some powder_charge else None)
      ~powder_lot
      ~primer_maker
      ~primer_type
      ~case_brand
      ~case_times_fired:(if case_times > 0 then Some case_times else None)
      ~coal_in:(if coal > 0.0 then Some coal else None)
      ~intended_use
      ~notes
      (GearTracker_ml.Id.generate ())
      cartridge
      date_created
  in

  match GearTracker_ml.ReloadRepo.add_reload_batch batch with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Reload batch added successfully! ID: %s" (GearTracker_ml.Id.to_string batch.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding reload: %s" (GearTracker_ml.Error.to_string e))

and delete_reload () =
  print_endline "";
  print_endline "=== Delete Reload Batch ===";
  let id_str = prompt_string "Reload Batch ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.ReloadRepo.delete_reload_batch id with
    | Ok () -> print_endline "Reload batch deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_borrowers () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Borrowers";
  print_endline "==========================================";
  match GearTracker_ml.CheckoutRepo.get_all_borrowers () with
  | Ok borrowers ->
    if borrowers = [] then
      print_endline "No borrowers found."
    else
      print_endline (Printf.sprintf "Found %d borrowers:" (List.length borrowers));
      print_endline "";
       List.iter (fun (b : GearTracker_ml.Checkout.borrower) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string b.id) b.name);
         print_endline (Printf.sprintf "     Phone: %s | Email: %s" b.phone b.email);
         (match b.notes with Some n -> print_endline (Printf.sprintf "     Notes: %s" n) | None -> ());
         print_endline ""
       ) borrowers
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_borrower () =
  print_endline "";
  print_endline "=== Add Borrower ===";
  let name = prompt_string "Name: " in
  let phone = prompt_string "Phone: " in
  let email = prompt_string "Email: " in
  let notes = prompt_optional "Notes (optional): " in

  let borrower = GearTracker_ml.Checkout.create_borrower
      ~phone
      ~email
      ~notes
      (GearTracker_ml.Id.generate ())
      name
  in

  match GearTracker_ml.CheckoutRepo.add_borrower borrower with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Borrower added successfully! ID: %s" (GearTracker_ml.Id.to_string borrower.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding borrower: %s" (GearTracker_ml.Error.to_string e))

and delete_borrower () =
  print_endline "";
  print_endline "=== Delete Borrower ===";
  let id_str = prompt_string "Borrower ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.CheckoutService.delete_borrower id with
    | Ok () -> print_endline "Borrower deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and checkout_item () =
  print_endline "";
  print_endline "=== Checkout Item ===";
  print_endline "Note: Enter item ID and type, borrower name";
  let item_id_str = prompt_string "Item ID: " in
  let item_type = prompt_string "Item Type (FIREARM, GEAR, NFA_ITEM): " in
  let borrower_name = prompt_string "Borrower Name: " in
  let expected_return_days = prompt_int ~default:0 "Expected Return (days from now, 0 for none): " in
  let notes = prompt_optional "Notes (optional): " in

  try
    let item_id = GearTracker_ml.Id.of_string item_id_str in
    let expected_return = if expected_return_days > 0 then
        Some (GearTracker_ml.Timestamp.add_seconds (GearTracker_ml.Timestamp.now ()) (expected_return_days * 24 * 60 * 60))
      else None
    in

    match GearTracker_ml.CheckoutService.checkout_item item_id item_type borrower_name expected_return notes with
    | Ok () -> print_endline "Item checked out successfully!"
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and return_item () =
  print_endline "";
  print_endline "=== Return Item ===";
  let checkout_id_str = prompt_string "Checkout ID: " in

  try
    let checkout_id = GearTracker_ml.Id.of_string checkout_id_str in
    match GearTracker_ml.CheckoutService.return_item checkout_id with
    | Ok () -> print_endline "Item returned successfully!"
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_loadouts () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Loadouts";
  print_endline "==========================================";
  match GearTracker_ml.LoadoutRepo.get_all_loadouts () with
  | Ok loadouts ->
    if loadouts = [] then
      print_endline "No loadouts found."
    else
      print_endline (Printf.sprintf "Found %d loadouts:" (List.length loadouts));
      print_endline "";
       List.iter (fun (l : GearTracker_ml.Loadout.loadout) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string l.id) l.name);
         (match l.description with Some d -> print_endline (Printf.sprintf "     Description: %s" d) | None -> ());
         print_endline (Printf.sprintf "     Created: %s" (format_timestamp l.created_date));
         print_endline ""
       ) loadouts
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and add_loadout () =
  print_endline "";
  print_endline "=== Add Loadout ===";
  let name = prompt_string "Name: " in
  let description = prompt_optional "Description (optional): " in
  let notes = prompt_optional "Notes (optional): " in
  let created_date = GearTracker_ml.Timestamp.now () in

  let loadout = GearTracker_ml.Loadout.create_loadout
      ~description
      ~notes
      (GearTracker_ml.Id.generate ())
      name
      created_date
  in

  match GearTracker_ml.LoadoutRepo.add_loadout loadout with
  | Ok () ->
    print_endline "";
    print_endline (Printf.sprintf "Loadout added successfully! ID: %s" (GearTracker_ml.Id.to_string loadout.id))
  | Error e ->
    print_endline (Printf.sprintf "Error adding loadout: %s" (GearTracker_ml.Error.to_string e))

and delete_loadout () =
  print_endline "";
  print_endline "=== Delete Loadout ===";
  let id_str = prompt_string "Loadout ID to delete: " in
  try
    let id = GearTracker_ml.Id.of_string id_str in
    match GearTracker_ml.LoadoutRepo.delete_loadout id with
    | Ok () -> print_endline "Loadout deleted successfully."
    | Error e -> print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))
  with _ ->
    print_endline "Invalid ID format."

and list_maintenance () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Items Needing Maintenance";
  print_endline "==========================================";
  match GearTracker_ml.FirearmRepo.get_all () with
  | Ok firearms ->
     let needs_maint = List.filter (fun (f : GearTracker_ml.Firearm.t) -> f.needs_maintenance) firearms in
    if needs_maint = [] then
      print_endline "No firearms currently marked as needing maintenance."
    else
      print_endline (Printf.sprintf "Found %d firearms needing attention:" (List.length needs_maint));
      print_endline "";
       List.iter (fun (f : GearTracker_ml.Firearm.t) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string f.id) f.name);
         print_endline (Printf.sprintf "     Issues: %s" f.maintenance_conditions);
         print_endline (Printf.sprintf "     Rounds since clean: %d (interval: %d)"
           f.rounds_fired f.clean_interval_rounds);
         print_endline ""
       ) needs_maint
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

and list_low_stock () =
  print_endline "";
  print_endline "==========================================";
  print_endline "  Low Stock Consumables";
  print_endline "==========================================";
  match GearTracker_ml.ConsumableRepo.get_low_stock () with
  | Ok consumables ->
    if consumables = [] then
      print_endline "All consumables are well stocked!"
    else
      print_endline (Printf.sprintf "Found %d low stock items:" (List.length consumables));
      print_endline "";
       List.iter (fun (c : GearTracker_ml.Consumable.consumable) ->
         print_endline (Printf.sprintf "[%s] %s" (GearTracker_ml.Id.to_string c.id) c.name);
         print_endline (Printf.sprintf "     Current: %d %s | Minimum: %d %s"
           c.quantity c.unit c.min_quantity c.unit);
         print_endline ""
       ) consumables
  | Error e ->
    print_endline (Printf.sprintf "Error: %s" (GearTracker_ml.Error.to_string e))

let run () =
  print_header ();
  print_endline "Use 'help' for commands or 'quit' to exit.";
  print_endline "";
  main_loop ()
