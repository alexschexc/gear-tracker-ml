
type loadout = {
  id : Id.t;
  name : string;
  description : string option;
  created_date : Timestamp.t;
  notes : string option;
  updated_at : Timestamp.t;
}

type loadout_item = {
  id : Id.t;
  loadout_id : Id.t;
  item_id : Id.t;
  item_type : string;
  notes : string option;
}

type loadout_consumable = {
  id : Id.t;
  loadout_id : Id.t;
  consumable_id : Id.t;
  quantity : int;
  notes : string option;
}

type loadout_checkout = {
  id : Id.t;
  loadout_id : Id.t;
  checkout_id : Id.t;
  return_date : Timestamp.t option;
  rounds_fired : int;
  rain_exposure : bool;
  ammo_type : string;
  notes : string option;
}

let create_loadout
    ?(description = None)
    ?(notes = None)
    id
    name
    created_date
  =
  let now = Timestamp.now () in
  {
    id;
    name;
    description;
    created_date;
    notes;
    updated_at = now;
  }

let create_loadout_item
    ?(notes = None)
    id
    loadout_id
    item_id
    item_type
  =
  {
    id;
    loadout_id;
    item_id;
    item_type;
    notes;
  }

let create_loadout_consumable
    ?(notes = None)
    id
    loadout_id
    consumable_id
    quantity
  =
  {
    id;
    loadout_id;
    consumable_id;
    quantity;
    notes;
  }

let create_loadout_checkout
    ?(return_date = None)
    ?(rounds_fired = 0)
    ?(rain_exposure = false)
    ?(ammo_type = "")
    ?(notes = None)
    id
    loadout_id
    checkout_id
  =
  {
    id;
    loadout_id;
    checkout_id;
    return_date;
    rounds_fired;
    rain_exposure;
    ammo_type;
    notes;
  }
