(* Initialize the production database *)

let () =
  print_endline "Initializing production database...";
  let db_path = Filename.concat (Sys.getenv "HOME") ".gear_tracker/tracker.db" in
  print_endline ("Database path: " ^ db_path);

  let open Sqlite3 in
  let db = db_open db_path in
  print_endline "Database opened.";

  (* Apply the full schema *)
  let schema_sql = Database.schema_sql in
  let stmt = prepare db schema_sql in
  ignore (step stmt);
  finalize stmt;
  print_endline "Schema applied.";

  close_db db;
  print_endline "Done!"
