(* gearTracker_ml - Vault/Multi-profile system *)

type vault = {
  name : string;
  path : string;
  created_at : int64;
}

let config_dir = Filename.concat (Sys.getenv "HOME") ".gear_tracker"

let vaults_dir = Filename.concat config_dir "vaults"

let current_vault_file = Filename.concat config_dir "current_vault"

let ensure_config_dir () =
  if not (Sys.file_exists config_dir) then
    Unix.mkdir config_dir 0o755

let ensure_vaults_dir () =
  ensure_config_dir ();
  if not (Sys.file_exists vaults_dir) then
    Unix.mkdir vaults_dir 0o755

let get_vault_path name =
  Filename.concat vaults_dir (name ^ ".db")

let vault_exists name =
  Sys.file_exists (get_vault_path name)

let get_current_vault_name () =
  if Sys.file_exists current_vault_file then
    try
      let ch = open_in current_vault_file in
      let name = input_line ch in
      close_in ch;
      if name = "" then None else Some name
    with _ -> None
  else
    None

let set_current_vault name =
  ensure_config_dir ();
  let ch = open_out current_vault_file in
  output_string ch name;
  close_out ch

let list_vaults () =
  ensure_vaults_dir ();
  let dirs = Sys.readdir vaults_dir in
  let vaults = ref [] in
  Array.iter (fun f ->
    if Filename.check_suffix f ".db" then
      let name = String.sub f 0 (String.length f - 3) in
      let path = Filename.concat vaults_dir f in
      let stat = Unix.stat path in
      vaults := { name; path; created_at = Int64.of_float stat.Unix.st_mtime } :: !vaults
  ) dirs;
  List.sort (fun a b -> String.compare a.name b.name) !vaults

let create_vault name =
  ensure_vaults_dir ();
  if vault_exists name then
    Error (`Vault_exists name)
  else
    let path = get_vault_path name in
    let db = Sqlite3.db_open path in
    let () = ignore (Sqlite3.exec db Database.schema_sql) in
    ignore (Sqlite3.db_close db);
    set_current_vault name;
    Ok { name; path; created_at = Int64.of_float (Unix.time ()) }

let delete_vault name =
  if not (vault_exists name) then
    Error (`Vault_not_found name)
  else
    let path = get_vault_path name in
    Sys.remove path;
    (match get_current_vault_name () with
     | Some n when n = name ->
       let ch = open_out current_vault_file in
       output_string ch "";
       close_out ch
     | _ -> ());
    Ok ()

let switch_vault name =
  if not (vault_exists name) then
    Error (`Vault_not_found name)
  else
    let () = set_current_vault name in
    Ok ()

let get_default_vault_path () =
  Filename.concat config_dir "tracker.db"

let init ?(force_default=false) () =
  ensure_config_dir ();
  match get_current_vault_name () with
  | Some name when not force_default && vault_exists name ->
    let path = get_vault_path name in
    Database.set_db_path path;
    Ok name
  | _ ->
    let path = get_default_vault_path () in
    Database.set_db_path path;
    set_current_vault "default";
    Ok "default"

let get_current_vault () =
  match get_current_vault_name () with
  | Some name when vault_exists name ->
    let path = get_vault_path name in
    let stat = Unix.stat path in
    Some { name; path; created_at = Int64.of_float stat.Unix.st_mtime }
  | _ ->
    None
