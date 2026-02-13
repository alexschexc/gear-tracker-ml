(* gearTracker_ml - Import/Export Module
   
   Comprehensive CSV import/export functionality for all entity types.
   Supports sectioned CSV format compatible with Python GearTracker.
*)

open Printf

(* ============================================================================
   Types
   ============================================================================ *)

type export_options = {
  include_firearms : bool;
  include_gear : bool;
  include_nfa_items : bool;
  include_attachments : bool;
  include_consumables : bool;
  include_reload_batches : bool;
  include_loadouts : bool;
  include_checkouts : bool;
  include_borrowers : bool;
  include_transfers : bool;
  include_maintenance_logs : bool;
  include_consumable_transactions : bool;
}

let default_export_options = {
  include_firearms = true;
  include_gear = true;
  include_nfa_items = true;
  include_attachments = true;
  include_consumables = true;
  include_reload_batches = true;
  include_loadouts = true;
  include_checkouts = true;
  include_borrowers = true;
  include_transfers = true;
  include_maintenance_logs = true;
  include_consumable_transactions = true;
}

type import_action =
  | Skip
  | Overwrite
  | Import_as_new
  | Cancel

type duplicate_info = {
  entity_type : string;
  id : Id.t;
  name : string;
  existing_record : string;
}

type entity_stats = {
  total_rows : int;
  imported : int;
  skipped : int;
  overwritten : int;
  errors : int;
}

type import_error_detail = {
  error_section : string;
  error_row : int;
  error_messages : string list;
}

type import_result = {
  success : bool;
  overall_stats : entity_stats;
  entity_stats : (string * entity_stats) list;
  error_details : import_error_detail list;
  cancelled : bool;
}

type validation_result =
  | Valid
  | Invalid of string list

(* ============================================================================
   Utility Functions
   ============================================================================ *)

let string_of_bool_opt = function
  | Some true -> "true"
  | Some false -> "false"
  | None -> ""

let bool_of_string_opt = function
  | "true" | "1" -> Some true
  | "false" | "0" -> Some false
  | "" -> None
  | _ -> None

let string_of_int_opt = function
  | Some i -> string_of_int i
  | None -> ""

let int_of_string_opt s =
  try Some (int_of_string s) with _ -> None

let string_of_float_opt = function
  | Some f -> string_of_float f
  | None -> ""

let float_of_string_opt s =
  try Some (float_of_string s) with _ -> None

let string_of_id_opt = function
  | Some id -> Id.to_string id
  | None -> ""

let id_of_string_opt s =
  try Some (Id.of_string s) with _ -> None

let escape_csv_field s =
  if String.contains s '"' || String.contains s ',' || String.contains s '\n' then
    let escaped = String.concat "\"\"" (String.split_on_char '"' s) in
    "\"" ^ escaped ^ "\""
  else
    s

let write_csv_line chan fields =
  let escaped = List.map escape_csv_field fields in
  fprintf chan "%s\n" (String.concat "," escaped)

(* ============================================================================
   CSV Export Functions
   ============================================================================ *)

let export_firearms_to_csv () =
  match FirearmRepo.get_all () with
  | Error e -> Error e
  | Ok firearms ->
    let buf = Buffer.create 1024 in
    (* Header *)
    Buffer.add_string buf "id,name,caliber,serial_number,purchase_date,notes,status,is_nfa,nfa_type,tax_stamp_id,form_type,barrel_length,trust_name,transfer_status,rounds_fired,clean_interval_rounds,oil_interval_days,needs_maintenance,maintenance_conditions,last_cleaned_at,last_oiled_at,created_at,updated_at\n";
    (* Data rows *)
    List.iter (fun (f : Firearm.t) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%s,%s,%s,%s,%s,%s"
        (Id.to_string f.id)
        (escape_csv_field f.name)
        (escape_csv_field f.caliber)
        (escape_csv_field f.serial_number)
        (Timestamp.to_iso8601 f.purchase_date)
        (escape_csv_field (Option.value f.notes ~default:""))
        (escape_csv_field f.status)
        (if f.is_nfa then "true" else "false")
        (escape_csv_field (Option.value f.nfa_type ~default:""))
        (escape_csv_field f.tax_stamp_id)
        (escape_csv_field f.form_type)
        (escape_csv_field f.barrel_length)
        (escape_csv_field f.trust_name)
        (escape_csv_field f.transfer_status)
        f.rounds_fired
        f.clean_interval_rounds
        f.oil_interval_days
        (if f.needs_maintenance then "true" else "false")
        (escape_csv_field f.maintenance_conditions)
        (match f.last_cleaned_at with Some t -> Timestamp.to_iso8601 t | None -> "")
        (match f.last_oiled_at with Some t -> Timestamp.to_iso8601 t | None -> "")
        (Timestamp.to_iso8601 f.created_at)
        (Timestamp.to_iso8601 f.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) firearms;
    Ok (Buffer.contents buf)

let export_soft_gear_to_csv () =
  match GearRepo.get_all_soft_gear () with
  | Error e -> Error e
  | Ok gear_list ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,category,brand,purchase_date,notes,status,created_at,updated_at\n";
    List.iter (fun (g : Gear.t) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string g.id)
        (escape_csv_field g.name)
        (escape_csv_field g.category)
        (escape_csv_field (Option.value g.brand ~default:""))
        (Timestamp.to_iso8601 g.purchase_date)
        (escape_csv_field (Option.value g.notes ~default:""))
        (escape_csv_field g.status)
        (Timestamp.to_iso8601 g.created_at)
        (Timestamp.to_iso8601 g.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) gear_list;
    Ok (Buffer.contents buf)

let export_nfa_items_to_csv () =
  match NFAItemRepo.get_all () with
  | Error e -> Error e
  | Ok nfa_items ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,nfa_type,manufacturer,serial_number,tax_stamp_id,caliber_bore,purchase_date,form_type,trust_name,notes,status,rounds_fired,clean_interval_rounds,oil_interval_days,needs_maintenance,maintenance_conditions,last_cleaned_at,last_oiled_at,created_at,updated_at\n";
    List.iter (fun (nfa : Gear.nfa_item) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%s,%s,%s,%s,%s,%s"
        (Id.to_string nfa.nfa_id)
        (escape_csv_field nfa.nfa_name)
        (escape_csv_field nfa.nfa_type)
        (escape_csv_field (Option.value nfa.manufacturer ~default:""))
        (escape_csv_field (Option.value nfa.serial_number ~default:""))
        (escape_csv_field nfa.tax_stamp_id)
        (escape_csv_field (Option.value nfa.caliber_bore ~default:""))
        (Timestamp.to_iso8601 nfa.nfa_purchase_date)
        (escape_csv_field (Option.value nfa.form_type ~default:""))
        (escape_csv_field (Option.value nfa.trust_name ~default:""))
        (escape_csv_field (Option.value nfa.nfa_notes ~default:""))
        (escape_csv_field nfa.nfa_status)
        nfa.rounds_fired
        nfa.clean_interval_rounds
        nfa.oil_interval_days
        (if nfa.needs_maintenance then "true" else "false")
        (escape_csv_field (Option.value nfa.maintenance_conditions ~default:""))
        (match nfa.last_cleaned_at with Some t -> Timestamp.to_iso8601 t | None -> "")
        (match nfa.last_oiled_at with Some t -> Timestamp.to_iso8601 t | None -> "")
        (Timestamp.to_iso8601 nfa.nfa_created_at)
        (Timestamp.to_iso8601 nfa.nfa_updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) nfa_items;
    Ok (Buffer.contents buf)

let export_attachments_to_csv () =
  match AttachmentRepo.get_all () with
  | Error e -> Error e
  | Ok attachments ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,category,brand,model,serial_number,purchase_date,mounted_on_firearm_id,mount_position,zero_distance_yards,zero_notes,notes,created_at,updated_at\n";
    List.iter (fun (att : Gear.attachment) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string att.att_id)
        (escape_csv_field att.att_name)
        (escape_csv_field att.att_category)
        (escape_csv_field (Option.value att.brand ~default:""))
        (escape_csv_field (Option.value att.model ~default:""))
        (escape_csv_field (Option.value att.serial_number ~default:""))
        (match att.att_purchase_date with Some t -> Timestamp.to_iso8601 t | None -> "")
        (match att.mounted_on_firearm_id with Some id -> Id.to_string id | None -> "")
        (escape_csv_field (Option.value att.mount_position ~default:""))
        (match att.zero_distance_yards with Some i -> string_of_int i | None -> "")
        (escape_csv_field (Option.value att.zero_notes ~default:""))
        (escape_csv_field (Option.value att.att_notes ~default:""))
        (Timestamp.to_iso8601 att.att_created_at)
        (Timestamp.to_iso8601 att.att_updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) attachments;
    Ok (Buffer.contents buf)

let export_consumables_to_csv () =
  match ConsumableRepo.get_all () with
  | Error e -> Error e
  | Ok consumables ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,category,unit,quantity,min_quantity,notes,purchase_price,created_at,updated_at\n";
    List.iter (fun (c : Consumable.consumable) ->
      let line = sprintf "%s,%s,%s,%s,%d,%d,%s,%s,%s,%s"
        (Id.to_string c.id)
        (escape_csv_field c.name)
        (escape_csv_field c.category)
        (escape_csv_field c.unit)
        c.quantity
        c.min_quantity
        (escape_csv_field (Option.value c.notes ~default:""))
        (match c.purchase_price with Some f -> string_of_float f | None -> "")
        (Timestamp.to_iso8601 c.created_at)
        (Timestamp.to_iso8601 c.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) consumables;
    Ok (Buffer.contents buf)

let export_reload_batches_to_csv () =
  match ReloadRepo.get_all_reload_batches () with
  | Error e -> Error e
  | Ok batches ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,cartridge,firearm_id,date_created,bullet_maker,bullet_model,bullet_weight_gr,powder_name,powder_charge_gr,powder_lot,primer_maker,primer_type,case_brand,case_times_fired,case_prep_notes,coal_in,crimp_style,test_date,avg_velocity,es,sd,group_size_inches,group_distance_yards,intended_use,status,notes,created_at,updated_at\n";
    List.iter (fun (rb : Reload.reload_batch) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string rb.id)
        (escape_csv_field rb.cartridge)
        (match rb.firearm_id with Some id -> Id.to_string id | None -> "")
        (Timestamp.to_iso8601 rb.date_created)
        (escape_csv_field rb.bullet_maker)
        (escape_csv_field rb.bullet_model)
        (match rb.bullet_weight_gr with Some i -> string_of_int i | None -> "")
        (escape_csv_field rb.powder_name)
        (match rb.powder_charge_gr with Some f -> string_of_float f | None -> "")
        (escape_csv_field rb.powder_lot)
        (escape_csv_field rb.primer_maker)
        (escape_csv_field rb.primer_type)
        (escape_csv_field rb.case_brand)
        (match rb.case_times_fired with Some i -> string_of_int i | None -> "")
        (escape_csv_field rb.case_prep_notes)
        (match rb.coal_in with Some f -> string_of_float f | None -> "")
        (escape_csv_field rb.crimp_style)
        (match rb.test_date with Some t -> Timestamp.to_iso8601 t | None -> "")
        (match rb.avg_velocity with Some i -> string_of_int i | None -> "")
        (match rb.es with Some i -> string_of_int i | None -> "")
        (match rb.sd with Some i -> string_of_int i | None -> "")
        (match rb.group_size_inches with Some f -> string_of_float f | None -> "")
        (match rb.group_distance_yards with Some i -> string_of_int i | None -> "")
        (escape_csv_field rb.intended_use)
        (escape_csv_field rb.status)
        (escape_csv_field (Option.value rb.notes ~default:""))
        (Timestamp.to_iso8601 rb.created_at)
        (Timestamp.to_iso8601 rb.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) batches;
    Ok (Buffer.contents buf)

let export_borrowers_to_csv () =
  match CheckoutRepo.get_all_borrowers () with
  | Error e -> Error e
  | Ok borrowers ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,phone,email,notes,created_at,updated_at\n";
    List.iter (fun (b : Checkout.borrower) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string b.id)
        (escape_csv_field b.name)
        (escape_csv_field b.phone)
        (escape_csv_field b.email)
        (escape_csv_field (Option.value b.notes ~default:""))
        (Timestamp.to_iso8601 b.created_at)
        (Timestamp.to_iso8601 b.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) borrowers;
    Ok (Buffer.contents buf)

let export_checkouts_to_csv () =
  match CheckoutRepo.get_checkout_history () with
  | Error e -> Error e
  | Ok checkouts ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,item_id,item_type,borrower_id,checkout_date,expected_return,actual_return,notes,created_at\n";
    List.iter (fun (c : Checkout.checkout) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string c.id)
        (Id.to_string c.item_id)
        (escape_csv_field c.item_type)
        (Id.to_string c.borrower_id)
        (Timestamp.to_iso8601 c.checkout_date)
        (match c.expected_return with Some t -> Timestamp.to_iso8601 t | None -> "")
        (match c.actual_return with Some t -> Timestamp.to_iso8601 t | None -> "")
        (escape_csv_field (Option.value c.notes ~default:""))
        (Timestamp.to_iso8601 c.created_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) checkouts;
    Ok (Buffer.contents buf)

let export_transfers_to_csv () =
  match TransferRepo.get_all () with
  | Error e -> Error e
  | Ok transfers ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,firearm_id,transfer_date,buyer_name,buyer_address,buyer_dl_number,buyer_ltc_number,sale_price,ffl_dealer,ffl_license,notes,created_at\n";
    List.iter (fun (t : TransferRepo.transfer) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string t.id)
        (Id.to_string t.firearm_id)
        (Timestamp.to_iso8601 t.transfer_date)
        (escape_csv_field t.buyer_name)
        (escape_csv_field t.buyer_address)
        (escape_csv_field t.buyer_dl_number)
        (escape_csv_field (Option.value t.buyer_ltc_number ~default:""))
        (match t.sale_price with Some f -> string_of_float f | None -> "")
        (escape_csv_field (Option.value t.ffl_dealer ~default:""))
        (escape_csv_field (Option.value t.ffl_license ~default:""))
        (escape_csv_field (Option.value t.notes ~default:""))
        (Timestamp.to_iso8601 t.created_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) transfers;
    Ok (Buffer.contents buf)

let export_maintenance_logs_to_csv () =
  match CheckoutRepo.get_all_maintenance () with
  | Error e -> Error e
  | Ok logs ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,item_id,item_type,log_type,date,details,ammo_count,photo_path,created_at\n";
    List.iter (fun (log : Checkout.maintenance_log) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s,%s,%s,%s"
        (Id.to_string log.id)
        (Id.to_string log.item_id)
        (escape_csv_field log.item_type)
        (escape_csv_field log.log_type)
        (Timestamp.to_iso8601 log.date)
        (escape_csv_field (Option.value log.details ~default:""))
        (match log.ammo_count with Some i -> string_of_int i | None -> "")
        (escape_csv_field (Option.value log.photo_path ~default:""))
        (Timestamp.to_iso8601 log.created_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) logs;
    Ok (Buffer.contents buf)

let export_consumable_transactions_to_csv () =
  (* This would require adding a get_all_transactions function to ConsumableRepo *)
  (* For now, return empty *)
  Ok "id,consumable_id,transaction_type,quantity,date,notes,created_at\n"

let export_loadouts_to_csv () =
  match LoadoutRepo.get_all_loadouts () with
  | Error e -> Error e
  | Ok loadouts ->
    let buf = Buffer.create 1024 in
    Buffer.add_string buf "id,name,description,created_date,notes,updated_at\n";
    List.iter (fun (l : Loadout.loadout) ->
      let line = sprintf "%s,%s,%s,%s,%s,%s"
        (Id.to_string l.id)
        (escape_csv_field l.name)
        (escape_csv_field (Option.value l.description ~default:""))
        (Timestamp.to_iso8601 l.created_date)
        (escape_csv_field (Option.value l.notes ~default:""))
        (Timestamp.to_iso8601 l.updated_at)
      in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n'
    ) loadouts;
    Ok (Buffer.contents buf)

let export_loadout_items_to_csv () =
  (* This would need a get_all_loadout_items function *)
  Ok "id,loadout_id,item_id,item_type,notes\n"

let export_loadout_consumables_to_csv () =
  (* This would need a get_all_loadout_consumables function *)
  Ok "id,loadout_id,consumable_id,quantity,notes\n"

let export_loadout_checkouts_to_csv () =
  (* This would need a get_all_loadout_checkouts function *)
  Ok "id,loadout_id,borrower_id,checkout_date,return_date,rounds_fired,rain_exposure,ammo_type,notes\n"

(* ============================================================================
   CSV Parsing Helper Functions
   ============================================================================ *)

let read_file path =
  let chan = open_in path in
  let rec read_all acc =
    try
      let line = input_line chan in
      read_all (line :: acc)
    with End_of_file ->
      close_in chan;
      List.rev acc
  in
  read_all []

let parse_csv_line line =
  let len = String.length line in
  let rec parse acc current in_quotes i =
    if i >= len then
      List.rev (current :: acc)
    else
      let c = line.[i] in
      match c with
      | '"' when in_quotes ->
        if i + 1 < len && line.[i + 1] = '"' then
          parse acc (current ^ "\"") in_quotes (i + 2)
        else
          parse acc current false (i + 1)
      | '"' -> parse acc current true (i + 1)
      | ',' when not in_quotes -> parse (current :: acc) "" in_quotes (i + 1)
      | c -> parse acc (current ^ String.make 1 c) in_quotes (i + 1)
  in
  parse [] "" false 0

let parse_sectioned_csv path =
  let lines = read_file path in
  let rec parse_sections acc current_section current_rows = function
    | [] ->
      (match current_section with
       | Some sec -> (sec, List.rev current_rows) :: acc
       | None -> acc)
    | line :: rest ->
      let trimmed = String.trim line in
      if String.length trimmed >= 2 && trimmed.[0] = '[' && trimmed.[String.length trimmed - 1] = ']' then
        let section_name = String.sub trimmed 1 (String.length trimmed - 2) in
        let new_acc = match current_section with
          | Some sec -> (sec, List.rev current_rows) :: acc
          | None -> acc
        in
        parse_sections new_acc (Some section_name) [] rest
      else if trimmed <> "" && trimmed.[0] <> ';' then
        let row = parse_csv_line trimmed in
        parse_sections acc current_section (row :: current_rows) rest
      else
        parse_sections acc current_section current_rows rest
  in
  parse_sections [] None [] lines

let get_field ~name headers row =
  try
    let rec find_index idx = function
      | [] -> None
      | h :: t -> if h = name then Some idx else find_index (idx + 1) t
    in
    match find_index 0 headers with
    | Some idx when idx < List.length row -> Some (List.nth row idx)
    | _ -> None
  with _ -> None

let get_required_field ~name headers row =
  match get_field ~name headers row with
  | Some "" | None -> Error [sprintf "Field '%s' is required" name]
  | Some v -> Ok v

let get_optional_field ~name headers row =
  match get_field ~name headers row with
  | Some "" | None -> None
  | Some v -> Some v

let get_int_field ~name headers row =
  match get_field ~name headers row with
  | Some "" -> Ok None
  | Some v -> (try Ok (Some (int_of_string v)) with _ -> Error [sprintf "Invalid integer for '%s'" name])
  | None -> Ok None

let get_int64_field ~name headers row =
  match get_field ~name headers row with
  | Some "" -> Ok None
  | Some v -> (try Ok (Some (Int64.of_string v)) with _ -> Error [sprintf "Invalid int64 for '%s'" name])
  | None -> Ok None

let get_float_field ~name headers row =
  match get_field ~name headers row with
  | Some "" -> Ok None
  | Some v -> (try Ok (Some (float_of_string v)) with _ -> Error [sprintf "Invalid float for '%s'" name])
  | None -> Ok None

let get_bool_field ~name headers row =
  match get_field ~name headers row with
  | Some "true" | Some "1" -> Ok (Some true)
  | Some "false" | Some "0" -> Ok (Some false)
  | Some "" -> Ok None
  | _ -> Error [sprintf "Invalid boolean for '%s'" name]

let get_timestamp_field ~name headers row =
  match get_field ~name headers row with
  | Some "" -> Ok None
  | Some v ->
    (match Timestamp.of_iso8601 v with
     | Ok ts -> Ok (Some ts)
     | Error _ -> Error [sprintf "Invalid date format for '%s'" name])
  | None -> Ok None

let get_id_field ~name headers row =
  match get_field ~name headers row with
  | Some "" -> Ok None
  | Some v -> (try Ok (Some (Id.of_string v)) with _ -> Error [sprintf "Invalid ID for '%s'" name])
  | None -> Ok None

(* ============================================================================
   Import Functions
   ============================================================================ *)

let import_firearm_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let name = match get_required_field ~name:"name" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let caliber = match get_required_field ~name:"caliber" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let serial_number = match get_required_field ~name:"serial_number" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date_str = match get_required_field ~name:"purchase_date" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date = match Timestamp.of_iso8601 purchase_date_str with
      | Ok ts -> ts
      | Error _ -> raise (Failure "Invalid purchase_date format")
    in
    let id = Id.of_string id_str in
    let notes = get_optional_field ~name:"notes" headers row in
    let is_nfa_str = get_field ~name:"is_nfa" headers row |> Option.value ~default:"false" in
    let is_nfa = is_nfa_str = "true" || is_nfa_str = "1" in
    let nfa_type = get_optional_field ~name:"nfa_type" headers row in
    let tax_stamp_id = get_field ~name:"tax_stamp_id" headers row |> Option.value ~default:"" in
    let form_type = get_field ~name:"form_type" headers row |> Option.value ~default:"" in
    let barrel_length = get_field ~name:"barrel_length" headers row |> Option.value ~default:"" in
    let trust_name = get_field ~name:"trust_name" headers row |> Option.value ~default:"" in
    let transfer_status = get_field ~name:"transfer_status" headers row |> Option.value ~default:"OWNED" in
    let rounds_fired = get_field ~name:"rounds_fired" headers row |> Option.map int_of_string |> Option.value ~default:0 in
    let clean_interval_rounds = get_field ~name:"clean_interval_rounds" headers row |> Option.map int_of_string |> Option.value ~default:500 in
    let oil_interval_days = get_field ~name:"oil_interval_days" headers row |> Option.map int_of_string |> Option.value ~default:90 in
    let needs_maintenance_str = get_field ~name:"needs_maintenance" headers row |> Option.value ~default:"false" in
    let needs_maintenance = needs_maintenance_str = "true" || needs_maintenance_str = "1" in
    let maintenance_conditions = get_field ~name:"maintenance_conditions" headers row |> Option.value ~default:"" in
    let last_cleaned_at = match get_field ~name:"last_cleaned_at" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let last_oiled_at = match get_field ~name:"last_oiled_at" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let firearm : Firearm.t = {
      Firearm.id;
      name;
      caliber;
      serial_number;
      purchase_date;
      notes;
      status = "AVAILABLE";
      is_nfa;
      nfa_type;
      tax_stamp_id;
      form_type;
      barrel_length;
      trust_name;
      transfer_status;
      rounds_fired;
      clean_interval_rounds;
      oil_interval_days;
      needs_maintenance;
      maintenance_conditions;
      last_cleaned_at;
      last_oiled_at;
      created_at;
      updated_at;
    } in
    Ok firearm
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_firearms_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_firearm_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok firearm ->
          (* Check for duplicates by ID *)
          match FirearmRepo.get_by_id firearm.id with
          | Ok (Some existing) ->
            let dup_info = {
              entity_type = "firearm";
              id = firearm.id;
              name = firearm.name;
              existing_record = existing.name;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match FirearmRepo.delete firearm.id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match FirearmRepo.add firearm with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let firearm = { firearm with Firearm.id = new_id } in
               (match FirearmRepo.add firearm with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (firearm :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Ok None ->
            (* Not found, import as new *)
            (match FirearmRepo.add firearm with
             | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
             | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (firearm :: acc))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let import_soft_gear_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let name = match get_required_field ~name:"name" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let category = match get_required_field ~name:"category" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date_str = match get_required_field ~name:"purchase_date" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date = match Timestamp.of_iso8601 purchase_date_str with
      | Ok ts -> ts
      | Error _ -> raise (Failure "Invalid purchase_date format")
    in
    let id = Id.of_string id_str in
    let brand = get_optional_field ~name:"brand" headers row in
    let notes = get_optional_field ~name:"notes" headers row in
    let status = get_field ~name:"status" headers row |> Option.value ~default:"AVAILABLE" in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let gear : Gear.t = {
      Gear.id;
      name;
      category;
      brand;
      purchase_date;
      notes;
      status;
      created_at;
      updated_at;
    } in
    Ok gear
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_soft_gear_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_soft_gear_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok gear ->
          (* Check for duplicates by ID *)
          match GearRepo.get_soft_gear gear.id with
          | Ok existing ->
            let dup_info = {
              entity_type = "soft_gear";
              id = gear.id;
              name = gear.name;
              existing_record = existing.name;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match GearRepo.delete_soft_gear gear.id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match GearRepo.add_soft_gear gear with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let gear = { gear with Gear.id = new_id } in
               (match GearRepo.add_soft_gear gear with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (gear :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Error _ ->
            (* Not found, import as new *)
            (match GearRepo.add_soft_gear gear with
             | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
             | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (gear :: acc))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let import_nfa_item_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let name = match get_required_field ~name:"name" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let nfa_type = match get_required_field ~name:"nfa_type" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let tax_stamp_id = match get_required_field ~name:"tax_stamp_id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date_str = match get_required_field ~name:"purchase_date" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let purchase_date = match Timestamp.of_iso8601 purchase_date_str with
      | Ok ts -> ts
      | Error _ -> raise (Failure "Invalid purchase_date format")
    in
    let id = Id.of_string id_str in
    let manufacturer = get_optional_field ~name:"manufacturer" headers row in
    let serial_number = get_optional_field ~name:"serial_number" headers row in
    let caliber_bore = get_optional_field ~name:"caliber_bore" headers row in
    let form_type = get_optional_field ~name:"form_type" headers row in
    let trust_name = get_optional_field ~name:"trust_name" headers row in
    let notes = get_optional_field ~name:"notes" headers row in
    let status = get_field ~name:"status" headers row |> Option.value ~default:"AVAILABLE" in
    let rounds_fired = get_field ~name:"rounds_fired" headers row |> Option.map int_of_string |> Option.value ~default:0 in
    let clean_interval_rounds = get_field ~name:"clean_interval_rounds" headers row |> Option.map int_of_string |> Option.value ~default:500 in
    let oil_interval_days = get_field ~name:"oil_interval_days" headers row |> Option.map int_of_string |> Option.value ~default:90 in
    let needs_maintenance_str = get_field ~name:"needs_maintenance" headers row |> Option.value ~default:"false" in
    let needs_maintenance = needs_maintenance_str = "true" || needs_maintenance_str = "1" in
    let maintenance_conditions = get_optional_field ~name:"maintenance_conditions" headers row in
    let last_cleaned_at = match get_field ~name:"last_cleaned_at" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let last_oiled_at = match get_field ~name:"last_oiled_at" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let nfa_item : Gear.nfa_item = {
      Gear.nfa_id = id;
      Gear.nfa_name = name;
      Gear.nfa_type;
      manufacturer;
      serial_number;
      Gear.tax_stamp_id = tax_stamp_id;
      caliber_bore;
      Gear.nfa_purchase_date = purchase_date;
      form_type;
      trust_name;
      Gear.nfa_notes = notes;
      Gear.nfa_status = status;
      Gear.rounds_fired = rounds_fired;
      Gear.clean_interval_rounds = clean_interval_rounds;
      Gear.oil_interval_days = oil_interval_days;
      Gear.needs_maintenance = needs_maintenance;
      Gear.maintenance_conditions = maintenance_conditions;
      Gear.last_cleaned_at = last_cleaned_at;
      Gear.last_oiled_at = last_oiled_at;
      Gear.nfa_created_at = created_at;
      Gear.nfa_updated_at = updated_at;
    } in
    Ok nfa_item
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_nfa_items_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_nfa_item_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok nfa_item ->
          (* Check for duplicates by ID *)
          match NFAItemRepo.get_by_id nfa_item.Gear.nfa_id with
          | Ok (Some existing) ->
            let dup_info = {
              entity_type = "nfa_item";
              id = nfa_item.Gear.nfa_id;
              name = nfa_item.Gear.nfa_name;
              existing_record = existing.Gear.nfa_name;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match NFAItemRepo.delete nfa_item.Gear.nfa_id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match NFAItemRepo.add nfa_item with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let nfa_item = { nfa_item with Gear.nfa_id = new_id } in
               (match NFAItemRepo.add nfa_item with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (nfa_item :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Ok None ->
            (* Not found, import as new *)
            (match NFAItemRepo.add nfa_item with
             | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
             | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (nfa_item :: acc))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let import_attachment_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let name = match get_required_field ~name:"name" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let category = match get_required_field ~name:"category" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let id = Id.of_string id_str in
    let brand = get_optional_field ~name:"brand" headers row in
    let model = get_optional_field ~name:"model" headers row in
    let serial_number = get_optional_field ~name:"serial_number" headers row in
    let att_purchase_date = match get_field ~name:"purchase_date" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let mounted_on_firearm_id = match get_id_field ~name:"mounted_on_firearm_id" headers row with
      | Ok (Some id) -> Some id
      | _ -> None
    in
    let mount_position = get_optional_field ~name:"mount_position" headers row in
    let zero_distance_yards = match get_int_field ~name:"zero_distance_yards" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let zero_notes = get_optional_field ~name:"zero_notes" headers row in
    let att_notes = get_optional_field ~name:"notes" headers row in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let attachment : Gear.attachment = {
      Gear.att_id = id;
      Gear.att_name = name;
      Gear.att_category = category;
      brand;
      model;
      serial_number;
      att_purchase_date;
      mounted_on_firearm_id;
      mount_position;
      zero_distance_yards;
      zero_notes;
      att_notes;
      att_created_at = created_at;
      att_updated_at = updated_at;
    } in
    Ok attachment
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_attachments_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_attachment_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok attachment ->
          (* Check for duplicates by ID *)
          match AttachmentRepo.get_by_id attachment.Gear.att_id with
          | Ok (Some existing) ->
            let dup_info = {
              entity_type = "attachment";
              id = attachment.Gear.att_id;
              name = attachment.Gear.att_name;
              existing_record = existing.Gear.att_name;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match AttachmentRepo.delete attachment.Gear.att_id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match AttachmentRepo.add attachment with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let attachment = { attachment with Gear.att_id = new_id } in
               (match AttachmentRepo.add attachment with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (attachment :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Ok None ->
            (* Not found, import as new *)
            (match AttachmentRepo.add attachment with
             | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
             | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (attachment :: acc))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let import_consumable_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let name = match get_required_field ~name:"name" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let category = match get_required_field ~name:"category" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let unit = match get_required_field ~name:"unit" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let id = Id.of_string id_str in
    let quantity = get_field ~name:"quantity" headers row |> Option.map int_of_string |> Option.value ~default:0 in
    let min_quantity = get_field ~name:"min_quantity" headers row |> Option.map int_of_string |> Option.value ~default:0 in
    let notes = get_optional_field ~name:"notes" headers row in
    let purchase_price = match get_float_field ~name:"purchase_price" headers row with
      | Ok (Some f) -> Some f
      | _ -> None
    in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let consumable : Consumable.consumable = {
      Consumable.id = id;
      name;
      category;
      unit;
      quantity;
      min_quantity;
      notes;
      purchase_price;
      created_at;
      updated_at;
    } in
    Ok consumable
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_consumables_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_consumable_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok consumable ->
          (* Check for duplicates by ID *)
          match ConsumableRepo.get_by_id consumable.Consumable.id with
          | Ok (Some existing) ->
            let dup_info = {
              entity_type = "consumable";
              id = consumable.Consumable.id;
              name = consumable.name;
              existing_record = existing.name;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match ConsumableRepo.delete consumable.Consumable.id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match ConsumableRepo.add consumable with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let consumable = { consumable with Consumable.id = new_id } in
               (match ConsumableRepo.add consumable with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (consumable :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Ok None ->
            (* Not found, import as new *)
            (match ConsumableRepo.add consumable with
             | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
             | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (consumable :: acc))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let import_reload_batch_row headers row =
  try
    let id_str = match get_required_field ~name:"id" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let cartridge = match get_required_field ~name:"cartridge" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let date_created_str = match get_required_field ~name:"date_created" headers row with
      | Ok v -> v
      | Error errs -> raise (Failure (String.concat "; " errs))
    in
    let date_created = match Timestamp.of_iso8601 date_created_str with
      | Ok ts -> ts
      | Error _ -> raise (Failure "Invalid date_created format")
    in
    let id = Id.of_string id_str in
    let firearm_id = match get_id_field ~name:"firearm_id" headers row with
      | Ok (Some id) -> Some id
      | _ -> None
    in
let bullet_maker = get_field ~name:"bullet_maker" headers row |> Option.value ~default:"" in
    let bullet_model = get_field ~name:"bullet_model" headers row |> Option.value ~default:"" in
    let powder_name = get_field ~name:"powder_name" headers row |> Option.value ~default:"" in
    let bullet_weight_gr = match get_int_field ~name:"bullet_weight_gr" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let powder_charge_gr = match get_float_field ~name:"powder_charge_gr" headers row with
      | Ok (Some f) -> Some f
      | _ -> None
    in
    let powder_lot = get_field ~name:"powder_lot" headers row |> Option.value ~default:"" in
    let primer_maker = get_field ~name:"primer_maker" headers row |> Option.value ~default:"" in
    let primer_type = get_field ~name:"primer_type" headers row |> Option.value ~default:"" in
    let case_brand = get_field ~name:"case_brand" headers row |> Option.value ~default:"" in
    let case_times_fired = match get_int_field ~name:"case_times_fired" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let case_prep_notes = get_field ~name:"case_prep_notes" headers row |> Option.value ~default:"" in
    let coal_in = match get_float_field ~name:"coal_in" headers row with
      | Ok (Some f) -> Some f
      | _ -> None
    in
    let crimp_style = get_field ~name:"crimp_style" headers row |> Option.value ~default:"" in
    let test_date = match get_field ~name:"test_date" headers row with
      | Some "" | None -> None
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> Some ts | Error _ -> None
    in
    let avg_velocity = match get_int_field ~name:"avg_velocity" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let es = match get_int_field ~name:"es" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let sd = match get_int_field ~name:"sd" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let group_size_inches = match get_float_field ~name:"group_size_inches" headers row with
      | Ok (Some f) -> Some f
      | _ -> None
    in
    let group_distance_yards = match get_int_field ~name:"group_distance_yards" headers row with
      | Ok (Some i) -> Some i
      | _ -> None
    in
    let intended_use = get_field ~name:"intended_use" headers row |> Option.value ~default:"" in
    let status = get_field ~name:"status" headers row |> Option.value ~default:"WORKUP" in
    let notes = get_optional_field ~name:"notes" headers row in
    let created_at = match get_field ~name:"created_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let updated_at = match get_field ~name:"updated_at" headers row with
      | Some "" | None -> Timestamp.now ()
      | Some s -> match Timestamp.of_iso8601 s with Ok ts -> ts | Error _ -> Timestamp.now ()
    in
    let reload_batch : Reload.reload_batch = {
      Reload.id = id;
      Reload.cartridge;
      firearm_id;
      date_created;
      bullet_maker;
      bullet_model;
      bullet_weight_gr;
      powder_name;
      powder_charge_gr;
      powder_lot;
      primer_maker;
      primer_type;
      case_brand;
      case_times_fired;
      case_prep_notes;
      coal_in;
      crimp_style;
      test_date;
      avg_velocity;
      es;
      sd;
      group_size_inches;
      group_distance_yards;
      intended_use;
      status;
      notes;
      created_at;
      updated_at;
    } in
    Ok reload_batch
  with Failure msg -> Error [msg]
    | e -> Error ["Unexpected error: " ^ Printexc.to_string e]

let import_reload_batches_section rows stats ~on_duplicate =
  let rec import_loop rows headers row_num stats acc =
    match rows with
    | [] -> Ok (List.rev acc, stats)
    | row :: rest ->
      if row_num = 0 then
        (* Header row, save it and continue *)
        import_loop rest row (row_num + 1) stats acc
      else
        match import_reload_batch_row headers row with
        | Error errs ->
          let stats = { stats with errors = stats.errors + 1 } in
          import_loop rest headers (row_num + 1) stats acc
        | Ok reload_batch ->
          (* Check for duplicates by ID *)
          match ReloadRepo.get_reload_batch_by_id reload_batch.Reload.id with
          | Ok existing ->
            let dup_info = {
              entity_type = "reload_batch";
              id = reload_batch.Reload.id;
              name = reload_batch.cartridge;
              existing_record = existing.cartridge;
            } in
            (match on_duplicate dup_info with
             | Skip -> import_loop rest headers (row_num + 1) { stats with skipped = stats.skipped + 1 } acc
             | Overwrite ->
               (match ReloadRepo.delete_reload_batch reload_batch.Reload.id with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () ->
                  (match ReloadRepo.add_reload_batch reload_batch with
                   | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                   | Ok () -> import_loop rest headers (row_num + 1) { stats with overwritten = stats.overwritten + 1 } acc))
             | Import_as_new ->
               let new_id = Id.generate () in
               let reload_batch = { reload_batch with Reload.id = new_id } in
               (match ReloadRepo.add_reload_batch reload_batch with
                | Error _ -> import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
                | Ok () -> import_loop rest headers (row_num + 1) { stats with imported = stats.imported + 1 } (reload_batch :: acc))
             | Cancel -> Error (Failure "Import cancelled"))
          | Error _ ->
            import_loop rest headers (row_num + 1) { stats with errors = stats.errors + 1 } acc
  in
  import_loop rows [] 0 stats []

let empty_stats = { total_rows = 0; imported = 0; skipped = 0; overwritten = 0; errors = 0 }

let import_all_from_csv ~path ~dry_run ~on_duplicate () =
  try
    let sections = parse_sectioned_csv path in
    let all_stats = ref [] in
    let has_errors = ref false in
    let cancelled = ref false in
    
    (* Process each section *)
    List.iter (fun (section_name, rows) ->
      if !cancelled then ()
      else if section_name = "FIREARMS" && List.length rows > 0 then
        match import_firearms_section rows empty_stats ~on_duplicate with
        | Error (Failure "Import cancelled") -> cancelled := true
        | Error _ -> has_errors := true
        | Ok (_, stats) ->
          all_stats := ("firearms", { stats with total_rows = List.length rows - 1 }) :: !all_stats
      else if section_name = "SOFT_GEAR" then
        match import_soft_gear_section rows empty_stats ~on_duplicate with
        | Error (Failure "Import cancelled") -> cancelled := true
        | Error _ -> has_errors := true
        | Ok (_, stats) ->
          all_stats := ("soft_gear", { stats with total_rows = List.length rows - 1 }) :: !all_stats
      else if section_name = "NFA_ITEMS" then
        match import_nfa_items_section rows empty_stats ~on_duplicate with
        | Error (Failure "Import cancelled") -> cancelled := true
        | Error _ -> has_errors := true
        | Ok (_, stats) ->
          all_stats := ("nfa_items", { stats with total_rows = List.length rows - 1 }) :: !all_stats
      else if section_name = "ATTACHMENTS" then
        match import_attachments_section rows empty_stats ~on_duplicate with
        | Error (Failure "Import cancelled") -> cancelled := true
        | Error _ -> has_errors := true
        | Ok (_, stats) ->
          all_stats := ("attachments", { stats with total_rows = List.length rows - 1 }) :: !all_stats
      else if section_name = "CONSUMABLES" then
        match import_consumables_section rows empty_stats ~on_duplicate with
        | Error (Failure "Import cancelled") -> cancelled := true
        | Error _ -> has_errors := true
        | Ok (_, stats) ->
          all_stats := ("consumables", { stats with total_rows = List.length rows - 1 }) :: !all_stats
      else if section_name = "RELOAD_BATCHES" then
        (* TODO: Implement reload batches import *)
        ()
      else if section_name = "BORROWERS" then
        (* TODO: Implement borrowers import *)
        ()
      else if section_name = "CHECKOUTS" then
        (* TODO: Implement checkouts import *)
        ()
      else if section_name = "TRANSFERS" then
        (* TODO: Implement transfers import *)
        ()
      else if section_name = "MAINTENANCE_LOGS" then
        (* TODO: Implement maintenance logs import *)
        ()
      else if section_name = "LOADOUTS" then
        (* TODO: Implement loadouts import *)
        ()
      else
        ()
    ) sections;
    
    (* Calculate overall stats *)
    let overall = List.fold_left (fun acc (_, stats) ->
      {
        total_rows = acc.total_rows + stats.total_rows;
        imported = acc.imported + stats.imported;
        skipped = acc.skipped + stats.skipped;
        overwritten = acc.overwritten + stats.overwritten;
        errors = acc.errors + stats.errors;
      }
    ) empty_stats !all_stats in
    
    Ok {
      success = not !has_errors && not !cancelled;
      overall_stats = overall;
      entity_stats = !all_stats;
      error_details = [];  (* TODO: Collect actual errors *)
      cancelled = !cancelled;
    }
  with
  | Failure msg -> Error (Error.IO_error msg)
  | e -> Error (Error.IO_error (Printexc.to_string e))

(* ============================================================================
   Complete Export
   ============================================================================ *)

let export_all_to_csv ~path ~options () =
  try
    let chan = open_out path in
    fprintf chan "; GearTracker Complete Export\n";
    fprintf chan "; Generated: %s\n" (Timestamp.to_iso8601 (Timestamp.now ()));
    fprintf chan "; Format: Sectioned CSV with [SECTION] headers\n\n";
    
    (if options.include_firearms then
      match export_firearms_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[FIREARMS]\n%s\n" data);
    
    (if options.include_gear then
      match export_soft_gear_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[SOFT_GEAR]\n%s\n" data);
    
    (if options.include_nfa_items then
      match export_nfa_items_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[NFA_ITEMS]\n%s\n" data);
    
    (if options.include_attachments then
      match export_attachments_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[ATTACHMENTS]\n%s\n" data);
    
    (if options.include_consumables then
      match export_consumables_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[CONSUMABLES]\n%s\n" data);
    
    (if options.include_reload_batches then
      match export_reload_batches_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[RELOAD_BATCHES]\n%s\n" data);
    
    (if options.include_borrowers then
      match export_borrowers_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[BORROWERS]\n%s\n" data);
    
    (if options.include_checkouts then
      match export_checkouts_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[CHECKOUTS]\n%s\n" data);
    
    (if options.include_transfers then
      match export_transfers_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[TRANSFERS]\n%s\n" data);
    
    (if options.include_maintenance_logs then
      match export_maintenance_logs_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[MAINTENANCE_LOGS]\n%s\n" data);
    
    (if options.include_loadouts then
      match export_loadouts_to_csv () with
      | Error e -> raise (Failure (Error.to_string e))
      | Ok data ->
        fprintf chan "[LOADOUTS]\n%s\n" data);
    
    close_out chan;
    Ok ()
  with
  | Failure msg -> Error (Error.IO_error msg)
  | e -> Error (Error.IO_error (Printexc.to_string e))
