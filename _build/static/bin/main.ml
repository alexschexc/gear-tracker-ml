(* gearTracker-ml - Main entry point *)

let () =
  print_endline "gearTracker-ml v0.1.0";
  print_endline "Database path: ~/.gear_tracker/tracker.db";
  Cli.run ()
