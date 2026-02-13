(* gearTracker_ml - Maintenance Service *)

let log_maintenance item_id item_type log_type details ammo_count photo_path =
  let date = Timestamp.now () in
  let maintenance_log = Checkout.create_maintenance_log
      ~details:(Some details) ~ammo_count ~photo_path
      (Id.generate ()) item_id item_type log_type date
  in
  CheckoutRepo.add_maintenance_log maintenance_log

let log_cleaning item_id item_type ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "CLEANING" details ammo_count photo_path

let log_fired_rounds item_id item_type rounds ?(details = "Range session") ?(photo_path = None) () =
  log_maintenance item_id item_type "FIRED_ROUNDS" details (Some rounds) photo_path

let log_lubrication item_id item_type ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "LUBRICATION" details ammo_count photo_path

let log_oiling item_id item_type ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "OILING" details ammo_count photo_path

let log_repair item_id item_type ?(details = "Repair completed") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "REPAIR" details ammo_count photo_path

let log_zeroing item_id item_type distance ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  let details = Printf.sprintf "Zeroed at %d yards. %s" distance details in
  log_maintenance item_id item_type "ZEROING" details ammo_count photo_path

let log_hunting item_id item_type ?(details = "Hunting trip") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "HUNTING" details ammo_count photo_path

let log_inspection item_id item_type ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "INSPECTION" details ammo_count photo_path

let log_rain_exposure item_id item_type ?(details = "Exposed to rain") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "RAIN_EXPOSURE" details ammo_count photo_path

let log_corrosive_ammo item_id item_type ammo_type ?(details = "") ?(ammo_count = None) ?(photo_path = None) () =
  let details = Printf.sprintf "Used corrosive ammo: %s. %s" ammo_type details in
  log_maintenance item_id item_type "CORROSIVE_AMMO" details ammo_count photo_path

let log_lead_ammo item_id item_type ?(details = "Used lead ammunition - clean thoroughly") ?(ammo_count = None) ?(photo_path = None) () =
  log_maintenance item_id item_type "LEAD_AMMO" details ammo_count photo_path

let get_maintenance_history item_id item_type =
  CheckoutRepo.get_maintenance_history item_id item_type

let get_maintenance_history_by_type item_id _item_type log_type =
  CheckoutRepo.get_logs_by_type item_id log_type

let get_all_maintenance () =
  CheckoutRepo.get_all_maintenance ()

let get_maintenance_status firearm_id =
  FirearmRepo.get_maintenance_status firearm_id

let needs_maintenance_soon firearm_id =
  let status_result = FirearmRepo.get_maintenance_status firearm_id in
  match status_result with
  | Ok (Some status) -> (status.FirearmRepo.needs_maintenance, status.FirearmRepo.reasons)
  | _ -> (false, [])

let get_firearms_needing_maintenance () =
  let firearms_result = FirearmRepo.get_all () in
  match firearms_result with
  | Ok firearms ->
      let rec check_firearms acc = function
        | [] -> acc
        | f :: rest ->
            let status_result = FirearmRepo.get_maintenance_status f.Firearm.id in
            match status_result with
            | Ok (Some status) when status.FirearmRepo.needs_maintenance ->
                check_firearms ((f, status.FirearmRepo.reasons) :: acc) rest
            | _ -> check_firearms acc rest
      in
      Ok (check_firearms [] firearms)
  | Error e -> Error e

let mark_maintenance_done firearm_id rounds_fired =
  let now = Timestamp.now () in
  FirearmRepo.log_maintenance firearm_id rounds_fired (Some now) (Some now) false

let mark_nfa_maintenance_done nfa_id =
  GearRepo.clear_nfa_maintenance_flag nfa_id
