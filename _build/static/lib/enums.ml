type firearm_status =
  | Available
  | Checked_out
  | Transferred
  | Lost
  | Retired

let string_of_firearm_status = function
  | Available -> "AVAILABLE"
  | Checked_out -> "CHECKED_OUT"
  | Transferred -> "TRANSFERRED"
  | Lost -> "LOST"
  | Retired -> "RETIRED"

let firearm_status_of_string = function
  | "AVAILABLE" -> Available
  | "CHECKED_OUT" -> Checked_out
  | "TRANSFERRED" -> Transferred
  | "LOST" -> Lost
  | "RETIRED" -> Retired
  | _ -> Available

type nfa_type =
  | Suppressor
  | Sbr
  | Sbs
  | Aow
  | Dd

let string_of_nfa_type = function
  | Suppressor -> "SUPPRESSOR"
  | Sbr -> "SBR"
  | Sbs -> "SBS"
  | Aow -> "AOW"
  | Dd -> "DD"

let nfa_type_of_string = function
  | "SUPPRESSOR" -> Suppressor
  | "SBR" -> Sbr
  | "SBS" -> Sbs
  | "AOW" -> Aow
  | "DD" -> Dd
  | _ -> Suppressor

type maintenance_type =
  | Cleaning
  | Lubrication
  | Repair
  | Zeroing
  | Hunting
  | Inspection
  | Fired_rounds
  | Oiling
  | Rain_exposure
  | Corrosive_ammo
  | Lead_ammo

let string_of_maintenance_type = function
  | Cleaning -> "CLEANING"
  | Lubrication -> "LUBRICATION"
  | Repair -> "REPAIR"
  | Zeroing -> "ZEROING"
  | Hunting -> "HUNTING"
  | Inspection -> "INSPECTION"
  | Fired_rounds -> "FIRED_ROUNDS"
  | Oiling -> "OILING"
  | Rain_exposure -> "RAIN_EXPOSURE"
  | Corrosive_ammo -> "CORROSIVE_AMMO"
  | Lead_ammo -> "LEAD_AMMO"

let maintenance_type_of_string = function
  | "CLEANING" -> Cleaning
  | "LUBRICATION" -> Lubrication
  | "REPAIR" -> Repair
  | "ZEROING" -> Zeroing
  | "HUNTING" -> Hunting
  | "INSPECTION" -> Inspection
  | "FIRED_ROUNDS" -> Fired_rounds
  | "OILING" -> Oiling
  | "RAIN_EXPOSURE" -> Rain_exposure
  | "CORROSIVE_AMMO" -> Corrosive_ammo
  | "LEAD_AMMO" -> Lead_ammo
  | _ -> Cleaning

type item_type =
  | Firearm
  | Gear
  | Nfa_item

let string_of_item_type = function
  | Firearm -> "FIREARM"
  | Gear -> "GEAR"
  | Nfa_item -> "NFA_ITEM"

type transfer_status =
  | Owned
  | Transferred

let string_of_transfer_status = function
  | Owned -> "OWNED"
  | Transferred -> "TRANSFERRED"

let transfer_status_of_string = function
  | "OWNED" -> Owned
  | "TRANSFERRED" -> Transferred
  | _ -> Owned

type reload_status =
  | Workup
  | Ready
  | Depleted

let string_of_reload_status = function
  | Workup -> "WORKUP"
  | Ready -> "READY"
  | Depleted -> "DEPLETED"

let reload_status_of_string = function
  | "WORKUP" -> Workup
  | "READY" -> Ready
  | "DEPLETED" -> Depleted
  | _ -> Workup
