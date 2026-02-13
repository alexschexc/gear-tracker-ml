(* test_import_export.ml - Test script for Import/Export functionality *)

open Printf

let test_export () =
  printf "Testing export functions...\n";
  
  (* Test firearms export *)
  match ImportExport.export_firearms_to_csv () with
  | Error e -> printf "  Firearms export failed: %s\n" (Error.to_string e)
  | Ok csv -> 
    printf "  Firearms export: OK (%d bytes)\n" (String.length csv);
    (* Print first 500 chars for inspection *)
    if String.length csv > 0 then
      printf "  First 200 chars:\n%s\n\n" (String.sub csv 0 (min 200 (String.length csv)))
    else
      printf "  (No firearms in database)\n"
  ;
  
  (* Test complete export *)
  let export_path = "/tmp/geartracker_test_export.csv" in
  match ImportExport.export_all_to_csv ~path:export_path ~options:ImportExport.default_export_options () with
  | Error e -> printf "  Complete export failed: %s\n" (Error.to_string e)
  | Ok () -> 
    printf "  Complete export: OK (written to %s)\n" export_path;
    (* Check file size *)
    let stats = Unix.stat export_path in
    printf "  File size: %d bytes\n" stats.Unix.st_size
  ;
  
  printf "\n"

let test_import () =
  printf "Testing import functions...\n";
  
  let import_path = "/tmp/geartracker_test_export.csv" in
  
  (* Check if export file exists *)
  if Sys.file_exists import_path then
    let duplicate_handler (dup : ImportExport.duplicate_info) =
      printf "  Duplicate found: %s (ID: %s) - Skipping\n" dup.name (Id.to_string dup.id);
      ImportExport.Skip
    in
    
    match ImportExport.import_all_from_csv ~path:import_path ~dry_run:false ~on_duplicate:duplicate_handler () with
    | Error e -> printf "  Import failed: %s\n" (Error.to_string e)
    | Ok result -> 
      printf "  Import completed:\n";
      printf "    Success: %b\n" result.success;
      printf "    Cancelled: %b\n" result.cancelled;
      printf "    Total rows: %d\n" result.overall_stats.total_rows;
      printf "    Imported: %d\n" result.overall_stats.imported;
      printf "    Skipped: %d\n" result.overall_stats.skipped;
      printf "    Overwritten: %d\n" result.overall_stats.overwritten;
      printf "    Errors: %d\n" result.overall_stats.errors;
      
      (* Print per-entity stats *)
      List.iter (fun (entity, stats) ->
        printf "    %s: %d imported, %d skipped, %d errors\n" 
          entity stats.imported stats.skipped stats.errors
      ) result.entity_stats
  else
    printf "  Skipping import test (no export file found)\n"
  ;
  
  printf "\n"

let test_csv_parsing () =
  printf "Testing CSV parsing...\n";
  
  (* Create a test CSV file *)
  let test_path = "/tmp/test_sectioned.csv" in
  let chan = open_out test_path in
  fprintf chan "; Test CSV file\n";
  fprintf chan "[FIREARMS]\n";
  fprintf chan "id,name,caliber\n";
  fprintf chan "1,Test Rifle,5.56mm\n";
  fprintf chan "2,Test Pistol,9mm\n";
  fprintf chan "[GEAR]\n";
  fprintf chan "id,name,category\n";
  fprintf chan "3,Test Backpack,Bags\n";
  close_out chan;
  
  (* Parse it *)
  let sections = ImportExport.parse_sectioned_csv test_path in
  printf "  Parsed %d sections:\n" (List.length sections);
  
  List.iter (fun (section, rows) ->
    printf "    %s: %d rows\n" section (List.length rows)
  ) sections;
  
  (* Cleanup *)
  Sys.remove test_path;
  
  printf "\n"

let main () =
  printf "=== GearTracker Import/Export Test ===\n\n";
  
  (* Initialize database *)
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/test_tracker.db" in
  Database.set_db_path db_path;
  
  (* Ensure directory exists *)
  let dir = Filename.dirname db_path in
  if not (Sys.file_exists dir) then Unix.mkdir dir 0o755;
  
  (* Initialize schema *)
  (match Database.init_schema () with
   | Error e -> printf "Warning: Schema init issue: %s\n" (Error.to_string e)
   | Ok () -> ());
  
  test_csv_parsing ();
  test_export ();
  test_import ();
  
  printf "=== Test Complete ===\n"

let () = main ()
