(* ImportExport.mli - Interface for Import/Export functionality *)

(** Export options for selective data export *)
type export_options = {
  include_firearms : bool;
  include_gear : bool;
  include_nfa_items : bool;
  include_attachments : bool;
  include_consumables : bool;
  include_reload_batches : bool;
  include_loadouts : bool;
  include_checkouts : bool;
  include_borrowers : bool;
  include_transfers : bool;
  include_maintenance_logs : bool;
  include_consumable_transactions : bool;
}

(** Default export options with all entities enabled *)
val default_export_options : export_options

(** Action to take when a duplicate is encountered during import *)
type import_action =
  | Skip              (** Skip the duplicate record *)
  | Overwrite         (** Overwrite the existing record *)
  | Import_as_new     (** Import as a new record with a new ID *)
  | Cancel            (** Cancel the entire import *)

(** Information about a duplicate record *)
type duplicate_info = {
  entity_type : string;      (** Type of entity (firearm, gear, etc.) *)
  id : Id.t;                 (** ID of the record *)
  name : string;             (** Name/display value *)
  existing_record : string;  (** Description of existing record *)
}

(** Statistics for a single entity type during import *)
type entity_stats = {
  total_rows : int;    (** Total number of rows processed *)
  imported : int;      (** Number of new records imported *)
  skipped : int;       (** Number of duplicates skipped *)
  overwritten : int;   (** Number of existing records overwritten *)
  errors : int;        (** Number of rows with errors *)
}

(** Detailed information about a specific import error *)
type import_error_detail = {
  error_section : string;      (** Section name where error occurred *)
  error_row : int;             (** Row number (1-based, excluding header) *)
  error_messages : string list; (** List of error messages *)
}

(** Result of an import operation *)
type import_result = {
  success : bool;                           (** Whether import completed successfully *)
  overall_stats : entity_stats;             (** Aggregated statistics across all entities *)
  entity_stats : (string * entity_stats) list; (** Per-entity statistics *)
  error_details : import_error_detail list; (** Detailed error information *)
  cancelled : bool;                         (** Whether import was cancelled *)
}

(** {2 Export Functions} *)

(** Export all firearms to CSV format 
    @return CSV string or error *)
val export_firearms_to_csv : unit -> (string, Error.t) result

(** Export all soft gear to CSV format
    @return CSV string or error *)
val export_soft_gear_to_csv : unit -> (string, Error.t) result

(** Export all NFA items to CSV format
    @return CSV string or error *)
val export_nfa_items_to_csv : unit -> (string, Error.t) result

(** Export all attachments to CSV format
    @return CSV string or error *)
val export_attachments_to_csv : unit -> (string, Error.t) result

(** Export all consumables to CSV format
    @return CSV string or error *)
val export_consumables_to_csv : unit -> (string, Error.t) result

(** Export all reload batches to CSV format
    @return CSV string or error *)
val export_reload_batches_to_csv : unit -> (string, Error.t) result

(** Export all borrowers to CSV format
    @return CSV string or error *)
val export_borrowers_to_csv : unit -> (string, Error.t) result

(** Export all checkouts to CSV format
    @return CSV string or error *)
val export_checkouts_to_csv : unit -> (string, Error.t) result

(** Export all transfers to CSV format
    @return CSV string or error *)
val export_transfers_to_csv : unit -> (string, Error.t) result

(** Export all maintenance logs to CSV format
    @return CSV string or error *)
val export_maintenance_logs_to_csv : unit -> (string, Error.t) result

(** Export all loadouts to CSV format
    @return CSV string or error *)
val export_loadouts_to_csv : unit -> (string, Error.t) result

(** Export complete database to sectioned CSV file
    @param path Output file path
    @param options Export options to control which entities to include
    @return unit or error *)
val export_all_to_csv : 
  path:string -> 
  options:export_options -> 
  unit -> 
  (unit, Error.t) result

(** {2 Import Functions} *)

(** Import all entities from a sectioned CSV file
    @param path Input file path
    @param dry_run If true, validate without importing
    @param on_duplicate Callback function to handle duplicates
    @return Import result or error *)
val import_all_from_csv :
  path:string ->
  dry_run:bool ->
  on_duplicate:(duplicate_info -> import_action) ->
  unit ->
  (import_result, Error.t) result

(** {2 Utility Functions} *)

(** Parse a sectioned CSV file into sections
    @param path Input file path
    @return List of (section_name, rows) tuples *)
val parse_sectioned_csv : string -> (string * string list list) list

(** Escape a field for CSV output
    @param s Field value
    @return Escaped field string *)
val escape_csv_field : string -> string
