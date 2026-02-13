(* import_export_example.ml - Import/Export usage example *)

open GearTracker_ml

let () =
  Printf.printf "=== Import/Export Example ===\n\n";
  
  (* Initialize database *)
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/example.db" in
  Database.set_db_path db_path;
  
  (* Example 1: Export all data *)
  Printf.printf "1. Exporting all data to CSV...\n";
  let export_path = "/tmp/geartracker_backup.csv" in
  let options = ImportExport.default_export_options in
  
  (match ImportExport.export_all_to_csv ~path:export_path ~options () with
   | Ok () ->
       let stats = Unix.stat export_path in
       Printf.printf "   Exported to: %s (%d bytes)\n" export_path stats.Unix.st_size
   | Error e ->
       Printf.printf "   Export failed: %s\n" (Error.to_string e));
  
  (* Example 2: Export selective data *)
  Printf.printf "\n2. Exporting only firearms and gear...\n";
  let selective_export_path = "/tmp/geartracker_selective.csv" in
  let selective_options : ImportExport.export_options = {
    ImportExport.include_firearms = true;
    ImportExport.include_gear = true;
    ImportExport.include_nfa_items = false;
    ImportExport.include_attachments = false;
    ImportExport.include_consumables = false;
    ImportExport.include_reload_batches = false;
    ImportExport.include_loadouts = false;
    ImportExport.include_checkouts = false;
    ImportExport.include_borrowers = false;
    ImportExport.include_transfers = false;
    ImportExport.include_maintenance_logs = false;
    ImportExport.include_consumable_transactions = false;
  } in
  
  (match ImportExport.export_all_to_csv ~path:selective_export_path ~options:selective_options () with
   | Ok () ->
       let stats = Unix.stat selective_export_path in
       Printf.printf "   Exported to: %s (%d bytes)\n" selective_export_path stats.Unix.st_size
   | Error e ->
       Printf.printf "   Export failed: %s\n" (Error.to_string e));
  
  (* Example 3: Import with duplicate handling *)
  Printf.printf "\n3. Importing data with duplicate handling...\n";
  
  let on_duplicate (dup : ImportExport.duplicate_info) =
    Printf.printf "   Duplicate detected: %s (ID: %s)\n" 
      dup.name 
      (Id.to_string dup.id);
    Printf.printf "   Action: Overwrite\n";
    ImportExport.Overwrite
  in
  
  (match ImportExport.import_all_from_csv 
     ~path:export_path 
     ~dry_run:false 
     ~on_duplicate 
     () with
   | Ok (result : ImportExport.import_result) ->
       Printf.printf "\n   Import Results:\n";
       Printf.printf "     Success: %b\n" result.ImportExport.success;
       Printf.printf "     Total rows: %d\n" result.ImportExport.overall_stats.ImportExport.total_rows;
       Printf.printf "     Imported: %d\n" result.ImportExport.overall_stats.ImportExport.imported;
       Printf.printf "     Skipped: %d\n" result.ImportExport.overall_stats.ImportExport.skipped;
       Printf.printf "     Overwritten: %d\n" result.ImportExport.overall_stats.ImportExport.overwritten;
       Printf.printf "     Errors: %d\n" result.ImportExport.overall_stats.ImportExport.errors;
       
        (* Print per-entity stats *)
        if List.length result.ImportExport.entity_stats > 0 then (
          Printf.printf "\n   Per-Entity Statistics:\n";
          List.iter (fun (entity, (stats : ImportExport.entity_stats)) ->
            Printf.printf "     %s: %d imported, %d skipped, %d errors\n"
              entity stats.ImportExport.imported stats.ImportExport.skipped stats.ImportExport.errors
          ) result.ImportExport.entity_stats
        )
   | Error e ->
       Printf.printf "   Import failed: %s\n" (Error.to_string e));
  
  (* Example 4: CSV parsing utilities *)
  Printf.printf "\n4. CSV parsing utilities...\n";
  let test_csv = "/tmp/test_data.csv" in
  let chan = open_out test_csv in
  output_string chan "[FIREARMS]\n";
  output_string chan "id,name,caliber\n";
  output_string chan "1,AR-15,5.56mm\n";
  output_string chan "2,Glock,9mm\n";
  close_out chan;
  
  let sections = ImportExport.parse_sectioned_csv test_csv in
  Printf.printf "   Parsed %d section(s)\n" (List.length sections);
  
  List.iter (fun (section_name, rows) ->
    Printf.printf "   Section '%s': %d row(s)\n" section_name (List.length rows)
  ) sections;
  
  (* Cleanup *)
  Sys.remove test_csv;
  Sys.remove export_path;
  Sys.remove selective_export_path;
  
  Printf.printf "\n=== Example Complete ===\n"
