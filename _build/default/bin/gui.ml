(* GearTracker ML - GTK3 GUI *)

let () = Printexc.record_backtrace true

module R = GearTracker_ml

let create_firearms_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Firearm" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_log = GButton.button ~label:"Log Maintenance" () in
  let btn_history = GButton.button ~label:"View History" () in
  let btn_delete = GButton.button ~label:"Delete" () in
  let btn_transfer = GButton.button ~label:"Transfer/Sell" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_log#coerce;
  btn_box#pack btn_history#coerce;
  btn_box#pack btn_delete#coerce;
  btn_box#pack btn_transfer#coerce;

  let cols = new GTree.column_list in
  let col_id = cols#add Gobject.Data.string in
  let col_name = cols#add Gobject.Data.string in
  let col_caliber = cols#add Gobject.Data.string in
  let col_serial = cols#add Gobject.Data.string in
  let col_status = cols#add Gobject.Data.string in
  let col_rounds = cols#add Gobject.Data.string in
  let col_notes = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;
  view#set_headers_clickable true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Caliber" col_caliber;
  add_col "Serial" col_serial;
  add_col "Status" col_status;
  add_col "Rounds" col_rounds;
  add_col "Notes" col_notes;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.FirearmRepo.get_all () with
    | Ok firearms ->
      store#clear ();
      List.iter (fun (f : R.Firearm.t) ->
          let row = store#append () in
          store#set ~row ~column:col_id (Int64.to_string f.id);
          store#set ~row ~column:col_name f.name;
          store#set ~row ~column:col_caliber f.caliber;
          store#set ~row ~column:col_serial f.serial_number;
          store#set ~row ~column:col_status f.status;
          store#set ~row ~column:col_rounds (string_of_int f.rounds_fired);
          store#set ~row ~column:col_notes (match f.notes with Some n -> n | None -> "");
        ) firearms;
      lbl_status#set_text (Printf.sprintf "Loaded %d firearms" (List.length firearms))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_log, btn_history, btn_delete, btn_transfer, refresh, view, col_id, store)

let get_selected_id ~(view:GTree.view) ~(col:'a GTree.column) ~(store:GTree.list_store) : int64 option =
  match view#selection#get_selected_rows with
  | path :: _ ->
      let iter = store#get_iter path in
      let id_str = store#get ~row:iter ~column:col in
      (try Some (Int64.of_string id_str) with _ -> None)
  | [] -> None

let create_gear_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Item" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_id = cols#add Gobject.Data.string in
  let col_name = cols#add Gobject.Data.string in
  let col_category = cols#add Gobject.Data.string in
  let col_status = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;
  view#set_headers_clickable true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Category" col_category;
  add_col "Status" col_status;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.GearRepo.get_all_soft_gear () with
    | Ok gear ->
      store#clear ();
      List.iter (fun (g : R.Gear.t) ->
          let row = store#append () in
          store#set ~row ~column:col_id (Int64.to_string g.id);
          store#set ~row ~column:col_name g.name;
          store#set ~row ~column:col_category g.category;
          store#set ~row ~column:col_status g.status;
        ) gear;
      lbl_status#set_text (Printf.sprintf "Loaded %d gear items" (List.length gear))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh, view, col_id, store)

let create_consumables_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Item" () in
  let btn_add_stock = GButton.button ~label:"Add Stock" () in
  let btn_use = GButton.button ~label:"Use Stock" () in
  let btn_history = GButton.button ~label:"View History" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_add_stock#coerce;
  btn_box#pack btn_use#coerce;
  btn_box#pack btn_history#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_name = cols#add Gobject.Data.string in
  let col_qty = cols#add Gobject.Data.string in
  let col_status = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Qty" col_qty;
  add_col "Status" col_status;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.ConsumableRepo.get_all () with
    | Ok items ->
      store#clear ();
      List.iter (fun (c : R.Consumable.consumable) ->
          let row = store#append () in
          store#set ~row ~column:col_name c.name;
          store#set ~row ~column:col_qty (Printf.sprintf "%d %s" c.quantity c.unit);
          let status = if c.quantity <= c.min_quantity then "LOW" else "OK" in
          store#set ~row ~column:col_status status;
        ) items;
      lbl_status#set_text (Printf.sprintf "Loaded %d consumables" (List.length items))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_add_stock, btn_use, btn_history, btn_delete, refresh)

let create_attachments_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Attachment" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_name = cols#add Gobject.Data.string in
  let col_category = cols#add Gobject.Data.string in
  let col_mounted = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Category" col_category;
  add_col "Mounted On" col_mounted;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.AttachmentRepo.get_all () with
    | Ok attachments ->
      store#clear ();
      List.iter (fun (a : R.Gear.attachment) ->
          let row = store#append () in
          store#set ~row ~column:col_name a.att_name;
          store#set ~row ~column:col_category a.att_category;
          let mounted = match a.mounted_on_firearm_id with
            | Some id -> "Firearm " ^ (string_of_int (Int64.to_int id))
            | None -> "Not mounted" in
          store#set ~row ~column:col_mounted mounted;
        ) attachments;
      lbl_status#set_text (Printf.sprintf "Loaded %d attachments" (List.length attachments))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_reloading_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Batch" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_cartridge = cols#add Gobject.Data.string in
  let col_status = cols#add Gobject.Data.string in
  let col_intended = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Cartridge" col_cartridge;
  add_col "Status" col_status;
  add_col "Intended Use" col_intended;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.ReloadRepo.get_all_reload_batches () with
    | Ok batches ->
      store#clear ();
      List.iter (fun (b : R.Reload.reload_batch) ->
          let row = store#append () in
          store#set ~row ~column:col_cartridge b.cartridge;
          store#set ~row ~column:col_status b.status;
          store#set ~row ~column:col_intended b.intended_use;
        ) batches;
      lbl_status#set_text (Printf.sprintf "Loaded %d reload batches" (List.length batches))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_loadouts_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Loadout" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_name = cols#add Gobject.Data.string in
  let col_items = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Items" col_items;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.LoadoutRepo.get_all_loadouts () with
    | Ok loadouts ->
      store#clear ();
      List.iter (fun (l : R.Loadout.loadout) ->
          let row = store#append () in
          store#set ~row ~column:col_name l.name;
          store#set ~row ~column:col_items (match l.description with Some d -> d | None -> "");
        ) loadouts;
      lbl_status#set_text (Printf.sprintf "Loaded %d loadouts" (List.length loadouts))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_checkouts_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_checkout = GButton.button ~label:"Checkout Item" () in
  let btn_return = GButton.button ~label:"Return Selected" () in

  btn_box#pack btn_checkout#coerce;
  btn_box#pack btn_return#coerce;

  let cols = new GTree.column_list in
  let col_item = cols#add Gobject.Data.string in
  let col_type = cols#add Gobject.Data.string in
  let col_date = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Item" col_item;
  add_col "Type" col_type;
  add_col "Date" col_date;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.CheckoutRepo.get_active_checkouts () with
    | Ok checkouts ->
      store#clear ();
      List.iter (fun (c : R.Checkout.checkout) ->
          let row = store#append () in
          store#set ~row ~column:col_item (string_of_int (Int64.to_int c.item_id));
          store#set ~row ~column:col_type c.item_type;
          store#set ~row ~column:col_date (R.Timestamp.to_string c.checkout_date);
        ) checkouts;
      lbl_status#set_text (Printf.sprintf "Loaded %d active checkouts" (List.length checkouts))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_checkout, btn_return, refresh)

let create_borrowers_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add Borrower" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_name = cols#add Gobject.Data.string in
  let col_phone = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Phone" col_phone;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.CheckoutRepo.get_all_borrowers () with
    | Ok borrowers ->
      store#clear ();
      List.iter (fun (b : R.Checkout.borrower) ->
          let row = store#append () in
          store#set ~row ~column:col_name b.name;
          store#set ~row ~column:col_phone b.phone;
        ) borrowers;
      lbl_status#set_text (Printf.sprintf "Loaded %d borrowers" (List.length borrowers))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_nfa_items_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Add NFA Item" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_name = cols#add Gobject.Data.string in
  let col_type = cols#add Gobject.Data.string in
  let col_status = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Name" col_name;
  add_col "Type" col_type;
  add_col "Status" col_status;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.NFAItemRepo.get_all () with
    | Ok items ->
      store#clear ();
      List.iter (fun (i : R.Gear.nfa_item) ->
          let row = store#append () in
          store#set ~row ~column:col_name i.nfa_name;
          store#set ~row ~column:col_type i.nfa_type;
          store#set ~row ~column:col_status i.nfa_status;
        ) items;
      lbl_status#set_text (Printf.sprintf "Loaded %d NFA items" (List.length items))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_transfers_tab () =
  let vbox = GPack.vbox () in
  let btn_box = GPack.hbox ~spacing:5 () in

  let btn_add = GButton.button ~label:"Record Transfer" () in
  let btn_edit = GButton.button ~label:"Edit" () in
  let btn_delete = GButton.button ~label:"Delete" () in

  btn_box#pack btn_add#coerce;
  btn_box#pack btn_edit#coerce;
  btn_box#pack btn_delete#coerce;

  let cols = new GTree.column_list in
  let col_firearm = cols#add Gobject.Data.string in
  let col_buyer = cols#add Gobject.Data.string in
  let col_date = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Firearm ID" col_firearm;
  add_col "Buyer" col_buyer;
  add_col "Date" col_date;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;
  vbox#pack btn_box#coerce;

  let refresh () =
    lbl_status#set_text "Loading...";
    match R.TransferRepo.get_all () with
    | Ok transfers ->
      store#clear ();
      List.iter (fun (t : R.TransferRepo.transfer) ->
          let row = store#append () in
          store#set ~row ~column:col_firearm (string_of_int (Int64.to_int t.firearm_id));
          store#set ~row ~column:col_buyer t.buyer_name;
          store#set ~row ~column:col_date (R.Timestamp.to_string t.transfer_date);
        ) transfers;
      lbl_status#set_text (Printf.sprintf "Loaded %d transfers" (List.length transfers))
    | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
  in

  (vbox, btn_add, btn_edit, btn_delete, refresh)

let create_import_export_tab () =
  let vbox = GPack.vbox ~spacing:10 () in
  vbox#pack (GMisc.label ~text:"Import/Export functionality" ())#coerce;

  let btn_box = GPack.hbox ~spacing:5 () in
  vbox#pack btn_box#coerce;

  let btn_import = GButton.button ~label:"Import CSV" () in
  let btn_export = GButton.button ~label:"Export CSV" () in

  btn_box#pack btn_import#coerce;
  btn_box#pack btn_export#coerce;

  let lbl_status = GMisc.label ~text:"Ready" () in
  vbox#pack lbl_status#coerce;

  let refresh () = lbl_status#set_text "Ready" in

  (vbox, btn_import, btn_export, refresh)

let show_message ~parent ~message ~message_type () =
  let dialog = GWindow.message_dialog ~parent ~message_type ~buttons:GWindow.Buttons.close ~message () in
  ignore (dialog#run ()); dialog#destroy ()

let show_info parent message = show_message ~parent ~message ~message_type:`INFO ()

let add_firearm_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Firearm" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let caliber_entry = create_entry "Caliber:" in
  let serial_entry = create_entry "Serial:" in
  let notes_entry = create_entry "Notes:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in
    let caliber = caliber_entry#text in
    let serial = serial_entry#text in
    let notes = if notes_entry#text = "" then None else Some notes_entry#text in

    if name <> "" && caliber <> "" && serial <> "" then
      let firearm = R.Firearm.create ~notes (R.Id.generate ()) name caliber serial (R.Timestamp.now ()) in
      Some (R.FirearmRepo.add firearm)
    else
      Some (Error (R.Error.validation_required_field "Name, caliber, serial required"))

let add_borrower_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Borrower" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let phone_entry = create_entry "Phone:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in
    let phone = phone_entry#text in

    if name <> "" then
      let borrower = R.Checkout.create_borrower ~phone ~email:"" ~notes:None (R.Id.generate ()) name in
      Some (R.CheckoutRepo.add_borrower borrower)
    else
      Some (Error (R.Error.validation_required_field "Name required"))

let add_gear_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Gear" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let category_entry = create_entry "Category:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in
    let category = category_entry#text in

    if name <> "" && category <> "" then
      let gear = R.Gear.create ~brand:None (R.Id.generate ()) name category (R.Timestamp.now ()) in
      Some (R.GearRepo.add_soft_gear gear)
    else
      Some (Error (R.Error.validation_required_field "Name and category required"))

let checkout_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Checkout Item" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let item_entry = create_entry "Item ID:" in
  let type_entry = create_entry "Type (FIREARM/GEAR):" in
  let borrower_entry = create_entry "Borrower:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Checkout" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let item_id = item_entry#text in
    let item_type = type_entry#text in
    let borrower = borrower_entry#text in

    if item_id <> "" && item_type <> "" && borrower <> "" then
      try Some (R.CheckoutService.checkout_item (Int64.of_string item_id) item_type borrower None None)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid item ID"))
    else
      Some (Error (R.Error.validation_required_field "All fields required"))

let delete_firearm_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Firearm" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Firearm ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.FirearmRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let delete_gear_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Gear" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Gear ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.GearRepo.delete_soft_gear (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let delete_consumable_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Consumable" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Consumable ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.ConsumableRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let use_stock_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Use Stock" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Consumable ID:" in
  let qty_entry = create_entry "Quantity to use:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Use" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let qty_text = qty_entry#text in

    if id_text <> "" && qty_text <> "" then
      try
        let id = Int64.of_string id_text in
        let qty = int_of_string qty_text in
        Some (R.ConsumableRepo.update_quantity id (-qty) "USE" None)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "All fields required"))

let return_checkout_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Return Item" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Checkout ID to return:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Return" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.CheckoutService.return_item (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid checkout ID"))
    else
      Some (Error (R.Error.validation_required_field "Checkout ID required"))

let delete_borrower_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Borrower" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Borrower ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.CheckoutRepo.delete_borrower (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let log_maintenance_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Log Maintenance" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Firearm ID:" in

  let type_hbox = GPack.hbox ~spacing:5 () in
  vbox#pack type_hbox#coerce;
  let type_lbl = GMisc.label ~text:"Type:" () in
  type_hbox#pack type_lbl#coerce;
  let type_combo = GEdit.combo_box_text ~strings:["CLEANING"; "OIL_CHANGE"; "INSPECTION"; "OTHER"] () in
  type_hbox#pack (fst type_combo)#coerce;

  let details_entry = create_entry "Details:" in
  let rounds_entry = create_entry "Rounds fired:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Log" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let type_text = match GEdit.text_combo_get_active type_combo with
      | Some t -> t
      | None -> "OTHER"
    in
    let details_text = details_entry#text in
    let rounds_text = rounds_entry#text in

    if id_text <> "" && type_text <> "" then
      try
        let id = Int64.of_string id_text in
        let details = if details_text = "" then None else Some details_text in
        let rounds = try Some (int_of_string rounds_text) with _ -> None in
        Some (R.MaintenanceService.log_maintenance id "FIREARM" type_text details rounds None)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "ID and type required"))

let view_maintenance_history_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Maintenance History" ~modal:true () in
  dialog#set_border_width 10;
  dialog#set_default_size ~width:600 ~height:400;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Firearm ID:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  let hbox2 = GPack.hbox ~spacing:5 () in
  vbox#pack hbox2#coerce;
  let btn_view = GButton.button ~label:"View History" () in
  hbox2#pack btn_view#coerce;
  let btn_close = GButton.button ~label:"Close" () in
  hbox2#pack btn_close#coerce;

  let cols = new GTree.column_list in
  let col_date = cols#add Gobject.Data.string in
  let col_type = cols#add Gobject.Data.string in
  let col_details = cols#add Gobject.Data.string in
  let col_rounds = cols#add Gobject.Data.string in

  let store = GTree.list_store cols in
  let view = GTree.view ~model:store () in
  view#set_rules_hint true;

  let add_col title col =
    let renderer = GTree.cell_renderer_text [] in
    let c = GTree.view_column ~title () in
    c#pack renderer;
    c#add_attribute renderer "text" col;
    ignore (view#append_column c)
  in
  add_col "Date" col_date;
  add_col "Type" col_type;
  add_col "Details" col_details;
  add_col "Rounds" col_rounds;

  let scrolled = GBin.scrolled_window ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ~shadow_type:`IN () in
  scrolled#add view#coerce;
  vbox#pack ~expand:true scrolled#coerce;

  let lbl_status = GMisc.label ~text:"Enter Firearm ID and click View History" () in
  vbox#pack lbl_status#coerce;

  let show_history () =
    let id_text = entry#text in
    if id_text <> "" then
      try
        let id = Int64.of_string id_text in
        match R.MaintenanceService.get_maintenance_history id "FIREARM" with
        | Ok logs ->
            store#clear ();
            List.iter (fun (l : R.Checkout.maintenance_log) ->
                let row = store#append () in
                store#set ~row ~column:col_date (R.Timestamp.to_string l.date);
                store#set ~row ~column:col_type l.log_type;
                store#set ~row ~column:col_details (match l.details with Some d -> d | None -> "");
                store#set ~row ~column:col_rounds (match l.ammo_count with Some r -> string_of_int r | None -> "");
              ) logs;
            lbl_status#set_text (Printf.sprintf "Loaded %d entries" (List.length logs))
        | Error e -> lbl_status#set_text ("Error: " ^ R.Error.to_string e)
      with _ -> lbl_status#set_text "Invalid Firearm ID"
    else
      lbl_status#set_text "Enter a Firearm ID"
  in

  ignore (btn_view#connect#clicked ~callback:show_history);
  ignore (btn_close#connect#clicked ~callback:(fun () -> dialog#destroy ()));

  dialog#add_button "Close" `CLOSE;
  ignore (dialog#run ());
  dialog#destroy ();
  None

let transfer_sell_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Transfer/Sell Firearm" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Firearm ID:" in
  let buyer_entry = create_entry "Buyer Name:" in
  let address_entry = create_entry "Buyer Address:" in
  let dl_entry = create_entry "Driver's License Number:" in
  let ltc_entry = create_entry "LTC Number (optional):" in
  let phone_entry = create_entry "Cell Phone:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Transfer" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let buyer = buyer_entry#text in
    let address = address_entry#text in
    let dl = dl_entry#text in
    let ltc = ltc_entry#text in
    let phone = phone_entry#text in

    if id_text <> "" && buyer <> "" && address <> "" && dl <> "" && phone <> "" then
      try
        let id = Int64.of_string id_text in
        let transfer = R.TransferRepo.create_transfer
            ~buyer_ltc_number:(if ltc = "" then None else Some ltc)
            (R.Id.generate ()) id (R.Timestamp.now ()) buyer address dl in
        let _ = R.TransferRepo.add transfer in
        Some (R.FirearmRepo.update_status id "SOLD")
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "All fields required (LTC is optional)"))

let edit_gear_dialog ~parent ?gear_id () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Gear" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry ?(text="") label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry ~text () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Gear ID:" in
  id_entry#set_editable false;

  let name_entry = create_entry "Name:" in
  let category_entry = create_entry "Category:" in
  let brand_entry = create_entry "Brand (optional):" in
  let notes_entry = create_entry "Notes:" in
  let status_entry = create_entry "Status (AVAILABLE/CHECKED_OUT/DAMAGED/RETIRED):" in

  let fill_gear_info () =
    match gear_id with
    | Some id ->
        id_entry#set_text (Int64.to_string id);
        (match R.GearRepo.get_soft_gear id with
         | Ok gear ->
             name_entry#set_text gear.name;
             category_entry#set_text gear.category;
             (match gear.brand with Some b -> brand_entry#set_text b | None -> ());
             (match gear.notes with Some n -> notes_entry#set_text n | None -> ());
             status_entry#set_text gear.status
         | Error _ -> ())
    | None -> ()
  in
  fill_gear_info ();

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Save" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let name = name_entry#text in
    let category = category_entry#text in
    let brand = if brand_entry#text = "" then None else Some brand_entry#text in
    let notes = if notes_entry#text = "" then None else Some notes_entry#text in
    let status = status_entry#text in

    if id_text <> "" && name <> "" && category <> "" && status <> "" then
      try
        let id = Int64.of_string id_text in
        (match R.GearRepo.get_soft_gear id with
         | Ok gear ->
             let updated_gear = { gear with name; category; brand; notes; status } in
             Some (R.GearRepo.update_soft_gear updated_gear)
         | Error e -> Some (Error e))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "Name, category, and status required"))

let add_stock_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Stock" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Consumable ID:" in
  let qty_entry = create_entry "Quantity to add:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let qty_text = qty_entry#text in

    if id_text <> "" && qty_text <> "" then
      try
        let id = Int64.of_string id_text in
        let qty = int_of_string qty_text in
        Some (R.ConsumableRepo.update_quantity id qty "STOCK_ADDITION" None)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "All fields required"))

let view_consumable_history_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Consumable History" ~modal:true () in
  dialog#set_border_width 10;
  dialog#set_default_size ~width:600 ~height:400;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let lbl = GMisc.label ~text:"History viewing for consumables is not yet implemented" () in
  vbox#pack lbl#coerce;

  dialog#add_button "Close" `CLOSE;
  ignore (dialog#run ());
  dialog#destroy ();
  None

let add_attachment_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Attachment" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let category_entry = create_entry "Category:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in
    let category = category_entry#text in

    if name <> "" && category <> "" then
      let att = R.Gear.create_attachment (R.Id.generate ()) name category in
      Some (R.AttachmentRepo.add att)
    else
      Some (Error (R.Error.validation_required_field "Name and category required"))

let delete_attachment_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Attachment" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Attachment ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.AttachmentRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let add_reload_batch_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Reload Batch" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let cartridge_entry = create_entry "Cartridge:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let cartridge = cartridge_entry#text in

    if cartridge <> "" then
      let batch = R.Reload.create_reload_batch (R.Id.generate ()) cartridge (R.Timestamp.now ()) in
      Some (R.ReloadRepo.add_reload_batch batch)
    else
      Some (Error (R.Error.validation_required_field "Cartridge required"))

let delete_reload_batch_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Reload Batch" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Batch ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.ReloadRepo.delete_reload_batch (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let add_loadout_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add Loadout" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let desc_entry = create_entry "Description:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in

    if name <> "" then
      let desc = if desc_entry#text = "" then None else Some desc_entry#text in
      let loadout = R.Loadout.create_loadout ~description:desc (R.Id.generate ()) name (R.Timestamp.now ()) in
      Some (R.LoadoutRepo.add_loadout loadout)
    else
      Some (Error (R.Error.validation_required_field "Name required"))

let delete_loadout_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Loadout" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Loadout ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.LoadoutService.delete_loadout (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let add_nfa_item_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Add NFA Item" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let name_entry = create_entry "Name:" in
  let type_entry = create_entry "Type (SILENCER/SHORT_BARREL/OTHER):" in
  let tax_stamp_entry = create_entry "Tax Stamp ID:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Add" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let name = name_entry#text in
    let nfa_type = type_entry#text in
    let tax_stamp = tax_stamp_entry#text in

    if name <> "" && nfa_type <> "" && tax_stamp <> "" then
      let item = R.Gear.create_nfa_item (R.Id.generate ()) name nfa_type tax_stamp (R.Timestamp.now ()) in
      Some (R.NFAItemRepo.add item)
    else
      Some (Error (R.Error.validation_required_field "Name, type, and tax stamp ID required"))

let delete_nfa_item_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete NFA Item" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"NFA Item ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.NFAItemRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let record_transfer_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Record Transfer" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let fw_id_entry = create_entry "Firearm ID:" in
  let buyer_entry = create_entry "Buyer Name:" in
  let address_entry = create_entry "Buyer Address:" in
  let dl_entry = create_entry "Buyer DL Number:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Record" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let fw_id = fw_id_entry#text in
    let buyer = buyer_entry#text in
    let address = address_entry#text in
    let dl = dl_entry#text in

    if fw_id <> "" && buyer <> "" && address <> "" && dl <> "" then
      try
        let transfer = R.TransferRepo.create_transfer
            (R.Id.generate ()) (Int64.of_string fw_id) (R.Timestamp.now ()) buyer address dl in
        Some (R.TransferRepo.add transfer)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid firearm ID"))
    else
      Some (Error (R.Error.validation_required_field "All fields required"))

let delete_transfer_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Delete Transfer" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let hbox = GPack.hbox ~spacing:5 () in
  vbox#pack hbox#coerce;
  let lbl = GMisc.label ~text:"Transfer ID to delete:" () in
  hbox#pack lbl#coerce;
  let entry = GEdit.entry () in
  hbox#pack entry#coerce;

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Delete" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = entry#text in

    if id_text <> "" then
      try Some (R.TransferRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let edit_attachment_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Attachment" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Attachment ID:" in
  let status_entry = create_entry "New Status (MOUNTED/UNMOUNTED):" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Update" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let _status = status_entry#text in

    if id_text <> "" then
      try Some (R.AttachmentRepo.delete (Int64.of_string id_text))
      with _ -> Some (Error (R.Error.validation_required_field "Invalid ID"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let edit_reload_batch_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Reload Batch" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Batch ID:" in
  let status_entry = create_entry "New Status (WORKUP/APPROVED/REJECTED):" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Update" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let status = status_entry#text in

    if id_text <> "" && status <> "" then
      try Some (R.ReloadRepo.update_reload_batch_status (Int64.of_string id_text) status)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "ID and status required"))

let edit_loadout_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Loadout" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Loadout ID:" in
  let desc_entry = create_entry "New Description:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Update" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let _desc = desc_entry#text in

    if id_text <> "" then
      Some (Error (R.Error.validation_required_field "Loadout editing not implemented"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let edit_borrower_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Borrower" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "Borrower ID:" in
  let phone_entry = create_entry "New Phone:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Update" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let _phone = phone_entry#text in

    if id_text <> "" then
      Some (Error (R.Error.validation_required_field "Borrower editing not implemented"))
    else
      Some (Error (R.Error.validation_required_field "ID required"))

let edit_nfa_item_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit NFA Item" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let create_entry label =
    let hbox = GPack.hbox ~spacing:5 () in
    vbox#pack hbox#coerce;
    let lbl = GMisc.label ~text:label () in
    hbox#pack lbl#coerce;
    let entry = GEdit.entry () in
    hbox#pack entry#coerce;
    entry
  in

  let id_entry = create_entry "NFA Item ID:" in
  let status_entry = create_entry "New Status:" in

  dialog#add_button "Cancel" `DELETE;
  dialog#add_button "Update" `ADD;

  let response = dialog#run () in
  dialog#destroy ();

  if response = `DELETE then None
  else
    let id_text = id_entry#text in
    let status = status_entry#text in

    if id_text <> "" && status <> "" then
      try Some (R.NFAItemRepo.update_status (Int64.of_string id_text) status)
      with _ -> Some (Error (R.Error.validation_required_field "Invalid input"))
    else
      Some (Error (R.Error.validation_required_field "ID and status required"))

let edit_transfer_dialog ~parent () =
  let dialog = GWindow.dialog ~parent ~title:"Edit Transfer" ~modal:true () in
  dialog#set_border_width 10;
  let vbox = GPack.vbox ~spacing:10 () in
  dialog#vbox#pack vbox#coerce;

  let lbl = GMisc.label ~text:"Transfer records cannot be edited once created." () in
  vbox#pack lbl#coerce;

  dialog#add_button "Close" `CLOSE;
  ignore (dialog#run ());
  dialog#destroy ();
  None

let main () =
  ignore (GtkMain.Main.init ());

  let window = GWindow.window ~title:"GearTracker ML" ~width:1000 ~height:600 () in
  ignore (window#connect#destroy ~callback:GtkMain.Main.quit);

  let vbox_main = GPack.vbox ~packing:window#add () in

  let menubar = GMenu.menu_bar ~packing:vbox_main#pack () in
  let file_item = GMenu.menu_item ~label:"File" () in
  let file_menu = GMenu.menu () in
  let quit_item = GMenu.menu_item ~label:"Quit" ~packing:file_menu#append () in
  ignore (menubar#append file_item);
  ignore (file_item#set_submenu file_menu);
  ignore (quit_item#connect#activate ~callback:GtkMain.Main.quit);

  let notebook = GPack.notebook ~packing:vbox_main#add () in
  notebook#set_tab_pos `TOP;

  let (fw_vbox, btn_add_fw, btn_edit_fw, btn_log_fw, btn_hist_fw, btn_del_fw, btn_trans_fw, refresh_fw, fw_view, fw_col_id, fw_store) = create_firearms_tab () in
  let fw_label = GMisc.label ~text:"Firearms" () in
  ignore (notebook#append_page fw_vbox#coerce ~tab_label:fw_label#coerce);

  let (att_vbox, btn_add_att, btn_edit_att, btn_del_att, refresh_att) = create_attachments_tab () in
  let att_label = GMisc.label ~text:"Attachments" () in
  ignore (notebook#append_page att_vbox#coerce ~tab_label:att_label#coerce);

  let (reload_vbox, btn_add_reload, btn_edit_reload, btn_del_reload, refresh_reload) = create_reloading_tab () in
  let reload_label = GMisc.label ~text:"Reloading" () in
  ignore (notebook#append_page reload_vbox#coerce ~tab_label:reload_label#coerce);

  let (gear_vbox, btn_add_gear, btn_edit_gear, btn_del_gear, refresh_gear, gear_view, gear_col_id, gear_store) = create_gear_tab () in
  let gear_label = GMisc.label ~text:"Gear" () in
  ignore (notebook#append_page gear_vbox#coerce ~tab_label:gear_label#coerce);

  let (cons_vbox, _, btn_add_stock, btn_use_cons, btn_hist_cons, btn_del_cons, refresh_cons) = create_consumables_tab () in
  let cons_label = GMisc.label ~text:"Consumables" () in
  ignore (notebook#append_page cons_vbox#coerce ~tab_label:cons_label#coerce);

  let (loadout_vbox, btn_add_loadout, btn_edit_loadout, btn_del_loadout, refresh_loadout) = create_loadouts_tab () in
  let loadout_label = GMisc.label ~text:"Loadouts" () in
  ignore (notebook#append_page loadout_vbox#coerce ~tab_label:loadout_label#coerce);

  let (checkout_vbox, btn_checkout, btn_return_checkout, refresh_checkout) = create_checkouts_tab () in
  let checkout_label = GMisc.label ~text:"Checkouts" () in
  ignore (notebook#append_page checkout_vbox#coerce ~tab_label:checkout_label#coerce);

  let (borrower_vbox, btn_add_borrower, btn_edit_borrower, btn_del_borrower, refresh_borrower) = create_borrowers_tab () in
  let borrower_label = GMisc.label ~text:"Borrowers" () in
  ignore (notebook#append_page borrower_vbox#coerce ~tab_label:borrower_label#coerce);

  let (nfa_vbox, btn_add_nfa, btn_edit_nfa, btn_del_nfa, refresh_nfa) = create_nfa_items_tab () in
  let nfa_label = GMisc.label ~text:"NFA Items" () in
  ignore (notebook#append_page nfa_vbox#coerce ~tab_label:nfa_label#coerce);

  let (trans_vbox, btn_add_trans, btn_edit_trans, btn_del_trans, refresh_trans) = create_transfers_tab () in
  let trans_label = GMisc.label ~text:"Transfers" () in
  ignore (notebook#append_page trans_vbox#coerce ~tab_label:trans_label#coerce);

  let (imex_vbox, btn_import, btn_export, refresh_imex) = create_import_export_tab () in
  let imex_label = GMisc.label ~text:"Import/Export" () in
  ignore (notebook#append_page imex_vbox#coerce ~tab_label:imex_label#coerce);

  ignore (btn_add_fw#connect#clicked ~callback:(fun () ->
      match add_firearm_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Firearm added!"; refresh_fw ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_edit_fw#connect#clicked ~callback:(fun () ->
      let selected_id = get_selected_id ~view:fw_view ~col:fw_col_id ~store:fw_store in
      match selected_id with
      | None -> show_info window "Please select a firearm to edit"
      | Some id -> show_info window ("Edit firearm " ^ Int64.to_string id)
    ));

  ignore (btn_log_fw#connect#clicked ~callback:(fun () ->
      match log_maintenance_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Maintenance logged!"; refresh_fw ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_hist_fw#connect#clicked ~callback:(fun () ->
      match view_maintenance_history_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_trans_fw#connect#clicked ~callback:(fun () ->
      match transfer_sell_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Firearm status updated!"; refresh_fw ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_add_gear#connect#clicked ~callback:(fun () ->
      match add_gear_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Gear added!"; refresh_gear ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_edit_gear#connect#clicked ~callback:(fun () ->
      let selected_id = get_selected_id ~view:gear_view ~col:gear_col_id ~store:gear_store in
      match selected_id with
      | None -> show_info window "Please select a gear item to edit"
      | Some id -> match edit_gear_dialog ~parent:window ~gear_id:id () with
          | None -> ()
          | Some (Ok ()) -> show_info window "Gear updated!"; refresh_gear ()
          | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_add_borrower#connect#clicked ~callback:(fun () ->
      match add_borrower_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Borrower added!"; refresh_borrower ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_checkout#connect#clicked ~callback:(fun () ->
      match checkout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Item checked out!"; refresh_checkout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_del_fw#connect#clicked ~callback:(fun () ->
      match delete_firearm_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Firearm deleted!"; refresh_fw ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_del_gear#connect#clicked ~callback:(fun () ->
      match delete_gear_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Gear deleted!"; refresh_gear ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_add_stock#connect#clicked ~callback:(fun () ->
      match add_stock_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Stock added!"; refresh_cons ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_use_cons#connect#clicked ~callback:(fun () ->
      match use_stock_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Stock used!"; refresh_cons ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_hist_cons#connect#clicked ~callback:(fun () ->
      match view_consumable_history_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_del_cons#connect#clicked ~callback:(fun () ->
      match delete_consumable_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Consumable deleted!"; refresh_cons ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_return_checkout#connect#clicked ~callback:(fun () ->
      match return_checkout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Item returned!"; refresh_checkout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_del_borrower#connect#clicked ~callback:(fun () ->
      match delete_borrower_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Borrower deleted!"; refresh_borrower ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));

  ignore (btn_add_att#connect#clicked ~callback:(fun () ->
      match add_attachment_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Attachment added!"; refresh_att ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_att#connect#clicked ~callback:(fun () ->
      match edit_attachment_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Attachment updated!"; refresh_att ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_att#connect#clicked ~callback:(fun () ->
      match delete_attachment_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Attachment deleted!"; refresh_att ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_att ();

  ignore (btn_add_reload#connect#clicked ~callback:(fun () ->
      match add_reload_batch_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Reload batch added!"; refresh_reload ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_reload#connect#clicked ~callback:(fun () ->
      match edit_reload_batch_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Reload batch updated!"; refresh_reload ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_reload#connect#clicked ~callback:(fun () ->
      match delete_reload_batch_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Reload batch deleted!"; refresh_reload ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_reload ();

  ignore (btn_add_loadout#connect#clicked ~callback:(fun () ->
      match add_loadout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Loadout added!"; refresh_loadout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_loadout#connect#clicked ~callback:(fun () ->
      match edit_loadout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Loadout updated!"; refresh_loadout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_loadout#connect#clicked ~callback:(fun () ->
      match delete_loadout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Loadout deleted!"; refresh_loadout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_loadout ();

  ignore (btn_add_nfa#connect#clicked ~callback:(fun () ->
      match add_nfa_item_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "NFA item added!"; refresh_nfa ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_nfa#connect#clicked ~callback:(fun () ->
      match edit_nfa_item_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "NFA item updated!"; refresh_nfa ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_nfa#connect#clicked ~callback:(fun () ->
      match delete_nfa_item_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "NFA item deleted!"; refresh_nfa ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_nfa ();

  ignore (btn_add_trans#connect#clicked ~callback:(fun () ->
      match record_transfer_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Transfer recorded!"; refresh_trans ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_trans#connect#clicked ~callback:(fun () ->
      match edit_transfer_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_trans#connect#clicked ~callback:(fun () ->
      match delete_transfer_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Transfer deleted!"; refresh_trans ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_trans ();

  ignore (btn_add_borrower#connect#clicked ~callback:(fun () ->
      match add_borrower_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Borrower added!"; refresh_borrower ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_edit_borrower#connect#clicked ~callback:(fun () ->
      match edit_borrower_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Borrower updated!"; refresh_borrower ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_borrower#connect#clicked ~callback:(fun () ->
      match delete_borrower_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Borrower deleted!"; refresh_borrower ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_loadout#connect#clicked ~callback:(fun () ->
      match delete_loadout_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Loadout deleted!"; refresh_loadout ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_loadout ();

  ignore (btn_add_nfa#connect#clicked ~callback:(fun () ->
      match add_nfa_item_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "NFA item added!"; refresh_nfa ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_nfa#connect#clicked ~callback:(fun () ->
      match delete_nfa_item_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "NFA item deleted!"; refresh_nfa ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_nfa ();

  ignore (btn_add_trans#connect#clicked ~callback:(fun () ->
      match record_transfer_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Transfer recorded!"; refresh_trans ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  ignore (btn_del_trans#connect#clicked ~callback:(fun () ->
      match delete_transfer_dialog ~parent:window () with
      | None -> ()
      | Some (Ok ()) -> show_info window "Transfer deleted!"; refresh_trans ()
      | Some (Error e) -> show_info window ("Error: " ^ R.Error.to_string e)
    ));
  refresh_trans ();

  ignore (btn_import#connect#clicked ~callback:(fun () -> show_info window "Import CSV not implemented"));
  ignore (btn_export#connect#clicked ~callback:(fun () -> show_info window "Export CSV not implemented"));
  refresh_imex ();

  refresh_fw ();
  refresh_gear ();
  refresh_cons ();
  refresh_checkout ();
  refresh_borrower ();

  window#show ();
  GtkMain.Main.main ()

let () = main ()
