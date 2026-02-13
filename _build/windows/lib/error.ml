type repository_error =
  | Not_found of { entity : string; id : Id.t }
  | Already_exists of { entity : string; field : string; value : string }
  | Constraint_violation of { entity : string; constraint_ : string }
  | Database_error of string
  | Connection_lost

type validation_error =
  | Required_field of string
  | Invalid_format of { field : string; expected : string; got : string }
  | Out_of_range of { field : string; min : int64; max : int64; value : int64 }
  | Duplicate of { entity : string; field : string; value : string }
  | Invalid_enum of { field : string; valid_values : string list; got : string }
  | Empty_string of string
  | Too_long of { field : string; max_length : int; length : int }

type domain_error =
  | Item_not_available of { entity : string; name : string; reason : string }
  | Item_already_checked_out of { entity : string; name : string }
  | Insufficient_stock of { consumable : string; available : int; requested : int }
  | Maintenance_required of { entity : string; name : string; reasons : string list }
  | Invalid_reference of { entity : string; field : string; referenced_entity : string; ref_id : Id.t }
  | Borrower_not_found of Id.t
  | Borrower_has_active_checkouts of Id.t
  | Circular_reference of { entity : string; field : string }

type import_error =
  | Parse_error of string
  | Invalid_section of string
  | Missing_section of string
  | Row_validation_failed of { section : string; row : int; errors : validation_error list }
  | Import_cancelled

type t =
  | Rep of repository_error
  | Val of validation_error
  | Dom of domain_error
  | Imp of import_error
  | IO_error of string
  | Unexpected of string

let string_of_repository_error = function
  | Not_found { entity; id } ->
    Printf.sprintf "%s with ID %s not found" entity (Id.to_string id)
  | Already_exists { entity; field; value } ->
    Printf.sprintf "%s already exists with %s='%s'" entity field value
  | Constraint_violation { entity; constraint_ } ->
    Printf.sprintf "Constraint violation on %s: %s" entity constraint_
  | Database_error msg ->
    Printf.sprintf "Database error: %s" msg
  | Connection_lost ->
    "Database connection lost"

let string_of_validation_error = function
  | Required_field field ->
    Printf.sprintf "Field '%s' is required" field
  | Invalid_format { field; expected; got } ->
    Printf.sprintf "Invalid format for '%s': expected %s, got '%s'" field expected got
  | Out_of_range { field; min; max; value } ->
    Printf.sprintf "'%s' out of range: %Ld (min: %Ld, max: %Ld)" field value min max
  | Duplicate { entity; field; value } ->
    Printf.sprintf "Duplicate %s with %s='%s'" entity field value
  | Invalid_enum { field; valid_values; got } ->
    Printf.sprintf "Invalid value '%s' for '%s'. Valid values: %s"
      got field (String.concat ", " valid_values)
  | Empty_string field ->
    Printf.sprintf "Field '%s' cannot be empty" field
  | Too_long { field; max_length; length } ->
    Printf.sprintf "'%s' too long: %d characters (max: %d)" field length max_length

let string_of_domain_error = function
  | Item_not_available { entity; name; reason } ->
    Printf.sprintf "%s '%s' is not available: %s" entity name reason
  | Item_already_checked_out { entity; name } ->
    Printf.sprintf "%s '%s' is already checked out" entity name
  | Insufficient_stock { consumable; available; requested } ->
    Printf.sprintf "Insufficient stock for %s: have %d, need %d" consumable available requested
  | Maintenance_required { entity; name; reasons } ->
    Printf.sprintf "%s '%s' requires maintenance: %s"
      entity name (String.concat "; " reasons)
  | Invalid_reference { entity; field; referenced_entity; ref_id } ->
    Printf.sprintf "Invalid reference in %s.%s: %s ID %s not found"
      entity field referenced_entity (Id.to_string ref_id)
  | Borrower_not_found id ->
    Printf.sprintf "Borrower with ID %s not found" (Id.to_string id)
  | Borrower_has_active_checkouts id ->
    Printf.sprintf "Borrower with ID %s has active checkouts" (Id.to_string id)
  | Circular_reference { entity; field } ->
    Printf.sprintf "Circular reference detected in %s.%s" entity field

let string_of_import_error = function
  | Parse_error msg -> Printf.sprintf "Parse error: %s" msg
  | Invalid_section sec -> Printf.sprintf "Invalid section '%s'" sec
  | Missing_section sec -> Printf.sprintf "Missing required section '%s'" sec
  | Row_validation_failed { section; row; errors } ->
    Printf.sprintf "Validation failed in %s row %d: %s"
      section row (String.concat "; " (List.map string_of_validation_error errors))
  | Import_cancelled -> "Import was cancelled"

let to_string = function
  | Rep e -> string_of_repository_error e
  | Val e -> string_of_validation_error e
  | Dom e -> string_of_domain_error e
  | Imp e -> string_of_import_error e
  | IO_error msg -> Printf.sprintf "I/O error: %s" msg
  | Unexpected msg -> Printf.sprintf "Unexpected error: %s" msg

let pp fmt err = Format.pp_print_string fmt (to_string err)

let failwith t = raise (Failure (to_string t))

let repository_not_found entity id = Rep (Not_found { entity; id })
let repository_already_exists entity field value = Rep (Already_exists { entity; field; value })
let repository_constraint_violation entity constraint_ = Rep (Constraint_violation { entity; constraint_ })
let repository_database_error msg = Rep (Database_error msg)
let repository_connection_lost = Rep Connection_lost

let validation_required_field field = Val (Required_field field)
let validation_invalid_format field expected got = Val (Invalid_format { field; expected; got })
let validation_out_of_range field min max value = Val (Out_of_range { field; min; max; value })
let validation_duplicate entity field value = Val (Duplicate { entity; field; value })
let validation_invalid_enum field valid_values got = Val (Invalid_enum { field; valid_values; got })
let validation_empty_string field = Val (Empty_string field)
let validation_too_long field max_length length = Val (Too_long { field; max_length; length })

let domain_item_not_available entity name reason = Dom (Item_not_available { entity; name; reason })
let domain_item_already_checked_out entity name = Dom (Item_already_checked_out { entity; name })
let domain_insufficient_stock consumable available requested = Dom (Insufficient_stock { consumable; available; requested })
let domain_maintenance_required entity name reasons = Dom (Maintenance_required { entity; name; reasons })
let domain_invalid_reference entity field referenced_entity ref_id = Dom (Invalid_reference { entity; field; referenced_entity; ref_id })
let domain_borrower_not_found id = Dom (Borrower_not_found id)
let domain_borrower_has_active_checkouts id = Dom (Borrower_has_active_checkouts id)
let domain_circular_reference entity field = Dom (Circular_reference { entity; field })

let import_parse_error msg = Imp (Parse_error msg)
let import_invalid_section sec = Imp (Invalid_section sec)
let import_missing_section sec = Imp (Missing_section sec)
let import_row_validation_failed section row errors = Imp (Row_validation_failed { section; row; errors })
let import_cancelled = Imp Import_cancelled
