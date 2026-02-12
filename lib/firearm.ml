
type t = {
  id : Id.t;
  name : string;
  caliber : string;
  serial_number : string;
  purchase_date : Timestamp.t;
  notes : string option;
  status : string;
  is_nfa : bool;
  nfa_type : string option;
  tax_stamp_id : string;
  form_type : string;
  barrel_length : string;
  trust_name : string;
  transfer_status : string;
  rounds_fired : int;
  clean_interval_rounds : int;
  oil_interval_days : int;
  needs_maintenance : bool;
  maintenance_conditions : string;
  last_cleaned_at : Timestamp.t option;
  last_oiled_at : Timestamp.t option;
  created_at : Timestamp.t;
  updated_at : Timestamp.t;
}

let create
    ?(notes = None)
    ?(is_nfa = false)
    ?(nfa_type = None)
    ?(tax_stamp_id = "")
    ?(form_type = "")
    ?(barrel_length = "")
    ?(trust_name = "")
    ?(transfer_status = "OWNED")
    ?(rounds_fired = 0)
    ?(clean_interval_rounds = 500)
    ?(oil_interval_days = 90)
    ?(needs_maintenance = false)
    ?(maintenance_conditions = "")
    ?(last_cleaned_at = None)
    ?(last_oiled_at = None)
    id
    name
    caliber
    serial_number
    purchase_date
  =
  let now = Timestamp.now () in
  {
    id;
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
    created_at = now;
    updated_at = now;
  }
