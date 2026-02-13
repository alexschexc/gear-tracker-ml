(* Test import/export functionality *)

open GearTracker_ml
open ImportExport

let test_export () =
  Printf.printf "Testing export functionality...\n";
  match ImportExport.export_firearms_to_csv () with
  | Error e -> Printf.printf "Export failed: %s\n" (Error.to_string e)
  | Ok csv -> 
    Printf.printf "Export successful! Sample:\n%s\n" (String.sub csv 0 (min 200 (String.length csv)));
    
  match ImportExport.export_all_to_csv ~path:"test_export.csv" ~options:ImportExport.default_export_options () with
  | Error e -> Printf.printf "Full export failed: %s\n" (Error.to_string e)
  | Ok () -> Printf.printf "Full export saved to test_export.csv\n"

let test_import () =
  Printf.printf "Testing import functionality...\n";
  
  (* Test with a simple duplicate resolution *)
  let on_duplicate dup_info =
    Printf.printf "Duplicate found: %s (%s)\n" dup_info.name dup_info.existing_record;
    Skip
  in
  
  match ImportExport.import_all_from_csv ~path:"test_export.csv" ~dry_run:false ~on_duplicate () with
  | Error e -> Printf.printf "Import failed: %s\n" (Error.to_string e)
  | Ok result ->
    Printf.printf "Import successful!\n";
    Printf.printf "Success: %b\n" result.success;
    Printf.printf "Total rows: %d\n" result.overall_stats.total_rows;
    Printf.printf "Imported: %d\n" result.overall_stats.imported;
    Printf.printf "Skipped: %d\n" result.overall_stats.skipped;
    Printf.printf "Errors: %d\n" result.overall_stats.errors

let () =
  Printf.printf "GearTracker-ML Import/Export Test\n";
  Printf.printf "================================\n";
  
  test_export ();
  test_import ();
  
  Printf.printf "Test completed.\n"