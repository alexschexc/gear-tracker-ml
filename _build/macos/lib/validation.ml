(* gearTracker_ml - Validation errors *)

type validation_error =
  | Empty_name
  | Invalid_caliber
  | Item_not_found of int
  | Item_not_available of string
  | Item_already_checked_out of string
  | Insufficient_stock of string * int * int
  | Maintenance_required of string
  | Borrower_not_found of int

let string_of_validation_error = function
  | Empty_name -> "Name cannot be empty"
  | Invalid_caliber -> "Invalid caliber format"
  | Item_not_found id -> Printf.sprintf "Item with ID %d not found" id
  | Item_not_available name -> Printf.sprintf "%s is not available" name
  | Item_already_checked_out name -> Printf.sprintf "%s is already checked out" name
  | Insufficient_stock (name, available, requested) ->
      Printf.sprintf "Insufficient stock for %s: available=%d, requested=%d" name available requested
  | Maintenance_required name -> Printf.sprintf "%s requires maintenance before use" name
  | Borrower_not_found id -> Printf.sprintf "Borrower with ID %d not found" id

let validate_name name =
  if String.trim name = "" then Error Empty_name else Ok ()

let validate_caliber caliber =
  if String.length caliber < 2 then Error Invalid_caliber else Ok ()
