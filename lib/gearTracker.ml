(* gearTracker_ml - Common types and utilities *)

type firearm_status =
  | Available
  | Checked_out
  | Transferred
  | Lost
  | Retired

type nfa_type =
  | Suppressor
  | Sbr
  | Sbs
  | Aow
  | Dd

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

type item_type =
  | Firearm
  | Gear
  | Nfa_item

let string_of_firearm_status = function
  | Available -> "AVAILABLE"
  | Checked_out -> "CHECKED_OUT"
  | Transferred -> "TRANSFERRED"
  | Lost -> "LOST"
  | Retired -> "RETIRED"

let string_of_nfa_type = function
  | Suppressor -> "SUPPRESSOR"
  | Sbr -> "SBR"
  | Sbs -> "SBS"
  | Aow -> "AOW"
  | Dd -> "DD"

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

let string_of_item_type = function
  | Firearm -> "FIREARM"
  | Gear -> "GEAR"
  | Nfa_item -> "NFA_ITEM"
