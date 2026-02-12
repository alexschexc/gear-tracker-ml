
type reload_batch = {
  id : Id.t;
  cartridge : string;
  firearm_id : Id.t option;
  date_created : Timestamp.t;
  bullet_maker : string;
  bullet_model : string;
  bullet_weight_gr : int option;
  powder_name : string;
  powder_charge_gr : float option;
  powder_lot : string;
  primer_maker : string;
  primer_type : string;
  case_brand : string;
  case_times_fired : int option;
  case_prep_notes : string;
  coal_in : float option;
  crimp_style : string;
  test_date : Timestamp.t option;
  avg_velocity : int option;
  es : int option;
  sd : int option;
  group_size_inches : float option;
  group_distance_yards : int option;
  intended_use : string;
  status : string;
  notes : string option;
  created_at : Timestamp.t;
  updated_at : Timestamp.t;
}

let create_reload_batch
    ?(firearm_id = None)
    ?(bullet_maker = "")
    ?(bullet_model = "")
    ?(bullet_weight_gr = None)
    ?(powder_name = "")
    ?(powder_charge_gr = None)
    ?(powder_lot = "")
    ?(primer_maker = "")
    ?(primer_type = "")
    ?(case_brand = "")
    ?(case_times_fired = None)
    ?(case_prep_notes = "")
    ?(coal_in = None)
    ?(crimp_style = "")
    ?(test_date = None)
    ?(avg_velocity = None)
    ?(es = None)
    ?(sd = None)
    ?(group_size_inches = None)
    ?(group_distance_yards = None)
    ?(intended_use = "")
    ?(status = "WORKUP")
    ?(notes = None)
    id
    cartridge
    date_created
  =
  let now = Timestamp.now () in
  {
    id;
    cartridge;
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
    created_at = now;
    updated_at = now;
  }
