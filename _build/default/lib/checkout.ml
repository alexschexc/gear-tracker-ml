
type borrower = {
  id : Id.t;
  name : string;
  phone : string;
  email : string;
  notes : string option;
  created_at : Timestamp.t;
  updated_at : Timestamp.t;
}

type checkout = {
  id : Id.t;
  item_id : Id.t;
  item_type : string;
  borrower_id : Id.t;
  checkout_date : Timestamp.t;
  expected_return : Timestamp.t option;
  actual_return : Timestamp.t option;
  notes : string option;
  created_at : Timestamp.t;
}

type maintenance_log = {
  id : Id.t;
  item_id : Id.t;
  item_type : string;
  log_type : string;
  date : Timestamp.t;
  details : string option;
  ammo_count : int option;
  photo_path : string option;
  created_at : Timestamp.t;
}

let create_borrower
    ?(phone = "")
    ?(email = "")
    ?(notes = None)
    id
    name
  =
  let now = Timestamp.now () in
  {
    id;
    name;
    phone;
    email;
    notes;
    created_at = now;
    updated_at = now;
  }

let create_checkout
    ?(expected_return = None)
    ?(actual_return = None)
    ?(notes = None)
    id
    item_id
    item_type
    borrower_id
    checkout_date
  =
  {
    id;
    item_id;
    item_type;
    borrower_id;
    checkout_date;
    expected_return;
    actual_return;
    notes;
    created_at = checkout_date;
  }

let create_maintenance_log
    ?(details = None)
    ?(ammo_count = None)
    ?(photo_path = None)
    id
    item_id
    item_type
    log_type
    date
  =
  {
    id;
    item_id;
    item_type;
    log_type;
    date;
    details;
    ammo_count;
    photo_path;
    created_at = date;
  }
