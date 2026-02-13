(* Inject sample data into the database *)

module R = GearTracker_ml

let () =
  Printf.printf "Injecting sample data...\n";

  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/tracker.db" in
  Printf.printf "Database path: %s\n" db_path;

  let now = R.Timestamp.now () in

  (* Sample firearms *)
  let fw1 = R.Firearm.create
      ~id:0L
      ~notes:(Some "Sample Rifle - AR-15 in 5.56 NATO")
      ~clean_interval_rounds:500
      ~oil_interval_days:90
      "Rifle" "AR-15" "AR-001" now
  in
  (match R.FirearmRepo.add fw1 with
   | Ok () -> Printf.printf "Added firearm: Rifle AR-15\n"
   | Error e -> Printf.printf "Error adding AR-15: %s\n" (R.Error.to_string e));

  let fw2 = R.Firearm.create
      ~id:0L
      ~notes:(Some "Sample Pistol - Glock 19 in 9mm")
      ~clean_interval_rounds:300
      ~oil_interval_days:60
      "Pistol" "Glock 19" "GLK-002" now
  in
  (match R.FirearmRepo.add fw2 with
   | Ok () -> Printf.printf "Added firearm: Pistol Glock 19\n"
   | Error e -> Printf.printf "Error adding Glock 19: %s\n" (R.Error.to_string e));

  let fw3 = R.Firearm.create
      ~id:0L
      ~notes:(Some "Sample Shotgun - Benelli M2 in 12 gauge")
      ~clean_interval_rounds:200
      ~oil_interval_days:90
      "Shotgun" "Benelli M2" "BEN-003" now
  in
  (match R.FirearmRepo.add fw3 with
   | Ok () -> Printf.printf "Added firearm: Shotgun Benelli M2\n"
   | Error e -> Printf.printf "Error adding Benelli: %s\n" (R.Error.to_string e));

  (* Sample NFA items *)
  let nfa1 = R.Gear.create_nfa_item
      ~id:0L
      ~notes:(Some "QD-762 suppressor")
      ~clean_interval_rounds:1000
      ~oil_interval_days:180
      " suppressor" "Silencer" "QD-762" now
  in
  (match R.NFAItemRepo.add nfa1 with
   | Ok () -> Printf.printf "Added NFA item: Silencer QD-762\n"
   | Error e -> Printf.printf "Error adding suppressor: %s\n" (R.Error.to_string e));

  let nfa2 = R.Gear.create_nfa_item
      ~id:0L
      ~notes:(Some "AR-15 SBR")
      ~clean_interval_rounds:500
      ~oil_interval_days:90
      " Short Barrel Rifle" "AR-15 SBR" "SBR-001" now
  in
  (match R.NFAItemRepo.add nfa2 with
   | Ok () -> Printf.printf "Added NFA item: AR-15 SBR\n"
   | Error e -> Printf.printf "Error adding SBR: %s\n" (R.Error.to_string e));

  (* Sample gear *)
  let gear1 = R.Gear.create
      ~id:0L
      ~notes:(Some "Sample Grip")
      ~brand:(Some "KAC")
      "KAC Vertical Grip" "Grip" now
  in
  (match R.GearRepo.add_soft_gear gear1 with
   | Ok () -> Printf.printf "Added gear: KAC Vertical Grip\n"
   | Error e -> Printf.printf "Error adding grip: %s\n" (R.Error.to_string e));

  let gear2 = R.Gear.create
      ~id:0L
      ~notes:(Some "Sample Optic")
      ~brand:(Some "EOTech")
      "EOTech EXPS3" "Optic" now
  in
  (match R.GearRepo.add_soft_gear gear2 with
   | Ok () -> Printf.printf "Added gear: EOTech EXPS3\n"
   | Error e -> Printf.printf "Error adding optic: %s\n" (R.Error.to_string e));

  (* Sample borrowers *)
  let b1 = R.Checkout.create_borrower
      ~id:0L
      ~phone:"555-0101" ~email:"" ~notes:None
      "John Smith"
  in
  (match R.CheckoutRepo.add_borrower b1 with
   | Ok () -> Printf.printf "Added borrower: John Smith\n"
   | Error e -> Printf.printf "Error adding borrower: %s\n" (R.Error.to_string e));

  let b2 = R.Checkout.create_borrower
      ~id:0L
      ~phone:"555-0102" ~email:"" ~notes:None
      "Jane Doe"
  in
  (match R.CheckoutRepo.add_borrower b2 with
   | Ok () -> Printf.printf "Added borrower: Jane Doe\n"
   | Error e -> Printf.printf "Error adding borrower: %s\n" (R.Error.to_string e));

  Printf.printf "\nSample data injection complete!\n"
