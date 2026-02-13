
type consumable = {
  id : Id.t;
  name : string;
  category : string;
  unit : string;
  quantity : int;
  min_quantity : int;
  notes : string option;
  purchase_price : float option;
  created_at : Timestamp.t;
  updated_at : Timestamp.t;
}

type consumable_transaction = {
  id : Id.t;
  consumable_id : Id.t;
  transaction_type : string;
  quantity : int;
  date : Timestamp.t;
  notes : string option;
  created_at : Timestamp.t;
}

let create_consumable
    ?(notes = None)
    ?(purchase_price = None)
    ?(quantity = 0)
    ?(min_quantity = 0)
    id
    name
    category
    unit
  =
  let now = Timestamp.now () in
  {
    id;
    name;
    category;
    unit;
    quantity;
    min_quantity;
    notes;
    purchase_price;
    created_at = now;
    updated_at = now;
  }

let create_consumable_transaction
    ?(notes = None)
    id
    consumable_id
    transaction_type
    quantity
    date
  =
  {
    id;
    consumable_id;
    transaction_type;
    quantity;
    date;
    notes;
    created_at = date;
  }
