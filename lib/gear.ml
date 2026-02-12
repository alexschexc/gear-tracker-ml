
type t = {
  id : Id.t;
  name : string;
  category : string;
  brand : string option;
  purchase_date : Timestamp.t;
  notes : string option;
  status : string;
  created_at : Timestamp.t;
  updated_at : Timestamp.t;
}

let create
    ?(brand = None)
    ?(notes = None)
    ?(status = "AVAILABLE")
    ?(id = 0L)
    name
    category
    purchase_date
  =
  let now = Timestamp.now () in
  {
    id;
    name;
    category;
    brand;
    purchase_date;
    notes;
    status;
    created_at = now;
    updated_at = now;
  }

type nfa_item = {
  nfa_id : Id.t;
  nfa_name : string;
  nfa_type : string;
  manufacturer : string option;
  serial_number : string option;
  tax_stamp_id : string;
  caliber_bore : string option;
  nfa_purchase_date : Timestamp.t;
  form_type : string option;
  trust_name : string option;
  nfa_notes : string option;
  nfa_status : string;
  rounds_fired : int;
  clean_interval_rounds : int;
  oil_interval_days : int;
  needs_maintenance : bool;
  maintenance_conditions : string option;
  last_cleaned_at : Timestamp.t option;
  last_oiled_at : Timestamp.t option;
  nfa_created_at : Timestamp.t;
  nfa_updated_at : Timestamp.t;
}

let create_nfa_item
    ?(manufacturer = None)
    ?(serial_number = None)
    ?(caliber_bore = None)
    ?(form_type = None)
    ?(trust_name = None)
    ?(notes = None)
    ?(maintenance_conditions = None)
    ?(status = "AVAILABLE")
    ?(rounds_fired = 0)
    ?(clean_interval_rounds = 500)
    ?(oil_interval_days = 90)
    ?(needs_maintenance = false)
    ?(last_cleaned_at = None)
    ?(last_oiled_at = None)
    ?(id = 0L)
    name
    nfa_type
    tax_stamp_id
    purchase_date
  =
  let now = Timestamp.now () in
  {
    nfa_id = id;
    nfa_name = name;
    nfa_type;
    manufacturer;
    serial_number;
    tax_stamp_id;
    caliber_bore;
    nfa_purchase_date = purchase_date;
    form_type;
    trust_name;
    nfa_notes = notes;
    nfa_status = status;
    rounds_fired;
    clean_interval_rounds;
    oil_interval_days;
    needs_maintenance;
    maintenance_conditions;
    last_cleaned_at;
    last_oiled_at;
    nfa_created_at = now;
    nfa_updated_at = now;
  }

type attachment = {
  att_id : Id.t;
  att_name : string;
  att_category : string;
  brand : string option;
  model : string option;
  serial_number : string option;
  att_purchase_date : Timestamp.t option;
  mounted_on_firearm_id : Id.t option;
  mount_position : string option;
  zero_distance_yards : int option;
  zero_notes : string option;
  att_notes : string option;
  att_created_at : Timestamp.t;
  att_updated_at : Timestamp.t;
}

let create_attachment
    ?(brand = None)
    ?(model = None)
    ?(serial_number = None)
    ?(purchase_date = None)
    ?(mounted_on_firearm_id = None)
    ?(mount_position = None)
    ?(zero_distance_yards = None)
    ?(zero_notes = None)
    ?(notes = None)
    id
    name
    category
  =
  let now = Timestamp.now () in
  {
    att_id = id;
    att_name = name;
    att_category = category;
    brand;
    model;
    serial_number;
    att_purchase_date = purchase_date;
    mounted_on_firearm_id;
    mount_position;
    zero_distance_yards;
    zero_notes;
    att_notes = notes;
    att_created_at = now;
    att_updated_at = now;
  }
