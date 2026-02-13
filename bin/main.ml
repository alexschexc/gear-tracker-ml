(* gearTracker-ml - Main entry point *)

module R = GearTracker_ml

let () =
  let vault_name = 
    match R.Vault.init () with
    | Ok name -> name
    | Error _ -> "default"
  in
  let vault_path = R.Database.get_db_path () in
  Printf.printf "gearTracker-ml v0.1.0\n";
  Printf.printf "Vault: %s\n" vault_name;
  Printf.printf "Database: %s\n" vault_path;
  print_endline "==========================================";
  Cli.run ()
