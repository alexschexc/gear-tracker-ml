(* test_import_export_simple.ml - Simple test for Import/Export *)

open Printf

let main () =
  printf "=== GearTracker Import/Export Test ===\n\n";
  
  (* Initialize database *)
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/test_tracker.db" in
  GearTracker_ml.Database.set_db_path db_path;
  
  (* Ensure directory exists *)
  let dir = Filename.dirname db_path in
  (try Unix.mkdir dir 0o755 with _ -> ());
  
  (* Initialize schema *)
  (match GearTracker_ml.Database.open_db () with
   | db ->
       GearTracker_ml.Database.init_schema db;
       GearTracker_ml.Database.close_db db;
       printf "Database initialized\n"
   | exception e -> printf "Warning: Schema init issue: %s\n" (Printexc.to_string e));
  
  (* Test 1: Export firearms *)
  printf "\n1. Testing firearms export...\n";
  (match GearTracker_ml.ImportExport.export_firearms_to_csv () with
   | Error e -> printf "   Failed: %s\n" (GearTracker_ml.Error.to_string e)
   | Ok csv -> 
     printf "   Success! Exported %d bytes\n" (String.length csv));
  
  (* Test 2: Export all data *)
  printf "\n2. Testing complete export...\n";
  let export_path = "/tmp/geartracker_test_export.csv" in
  (match GearTracker_ml.ImportExport.export_all_to_csv 
     ~path:export_path 
     ~options:GearTracker_ml.ImportExport.default_export_options () with
   | Error e -> printf "   Failed: %s\n" (GearTracker_ml.Error.to_string e)
   | Ok () -> 
     let stats = Unix.stat export_path in
     printf "   Success! Exported to %s (%d bytes)\n" export_path stats.Unix.st_size);
  
  (* Test 3: Import (if export succeeded) *)
  if Sys.file_exists export_path then
    let open GearTracker_ml.ImportExport in
    printf "\n3. Testing import...\n";
    let on_duplicate dup =
      printf "   Duplicate: %s - Skipping\n" dup.name;
      Skip
    in
    (match import_all_from_csv ~path:export_path ~dry_run:false ~on_duplicate () with
     | Error e -> printf "   Failed: %s\n" (GearTracker_ml.Error.to_string e)
     | Ok result ->
       printf "   Success!\n";
       printf "     Total rows: %d\n" result.overall_stats.total_rows;
       printf "     Imported: %d\n" result.overall_stats.imported;
       printf "     Skipped: %d\n" result.overall_stats.skipped;
       printf "     Errors: %d\n" result.overall_stats.errors);
  
  printf "\n=== Test Complete ===\n"

let () = main ()
