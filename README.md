# GearTracker ML

A comprehensive firearms and gear tracking application written in OCaml.

## Features

- **Firearms Inventory** - Track firearms with caliber, serial numbers, maintenance schedules
- **NFA Items** - Special handling for NFA items (SBR, SBS, AOW, etc.)
- **Soft Gear** - Clothing, accessories, and general gear
- **Attachments** - Scopes, magazines, and other firearm accessories
- **Consumables** - Ammo, cleaning supplies, and other consumables
- **Reload Batches** - Track handloaded ammunition with detailed specifications
- **Loadouts** - Create and manage equipment loadouts
- **Checkouts** - Track items checked out to borrowers
- **Import/Export** - CSV and JSON export capabilities

## Installation

```bash
# Using opam (not yet published)
opam install gearTracker-ml

# From source
git clone https://github.com/anomalyco/gearTracker-ml.git
cd gearTracker-ml
opam install --deps-only .
dune build
dune install
```

## Usage

### CLI

```bash
# Run the interactive CLI
gearTracker-ml

# Commands:
#   list-firearms  - List all firearms
#   list-gear      - List all gear
#   list-consumables - List consumables
#   list-reloads   - List reload batches
#   list-loadouts  - List loadouts
#   list-checkouts - List active checkouts
#   list-borrowers - List all borrowers
#   overdue        - Show items needing maintenance
#   help           - Show menu
#   quit           - Exit
```

### Library Usage

```ocaml
(* Open the library *)
open GearTracker_ml

(* Create a firearm *)
let firearm = GearTracker_types.Firearm.create
    ~notes:None
    (GearTracker_types.Core.Id.generate ())
    "AR-15"
    "5.56mm"
    "SN12345"
    1000L  (* purchase_date *)
in

(* Add to database *)
match Firearm_repo.add firearm with
| Ok () -> print_endline "Firearm added!"
| Error e -> print_endline ("Error: " ^ GearTracker_types.Core.Error.to_string e)

(* List all firearms *)
match Firearm_repo.get_all () with
| Ok firearms ->
    List.iter (fun f ->
        print_endline (Printf.sprintf "- %s (%s)" f.name f.caliber)
    ) firearms
| Error e -> print_endline ("Error: " ^ GearTracker_types.Core.Error.to_string e)
```

## Database

The application uses SQLite for storage. By default, the database is located at:
`~/.gear_tracker/tracker.db`

You can set a custom path:
```ocaml
GearTracker_ml.Database.set_db_path "/path/to/tracker.db"
```

## Building

```bash
# Build the library and CLI
dune build

# Run tests
dune test

# Run the CLI
dune exec -- gearTracker-ml
```

## Project Structure

```
gearTracker-ml/
├── bin/
│   ├── main.ml          # CLI entry point
│   └── cli.ml           # CLI interface
├── lib/
│   ├── types/           # Domain types
│   │   ├── core.ml     # Core types (Id, Timestamp, Error)
│   │   ├── enums.ml    # Enumeration types
│   │   ├── firearm.ml   # Firearm type
│   │   ├── gear.ml      # Gear, NFA items, attachments
│   │   ├── checkout.ml   # Checkout and maintenance types
│   │   ├── consumable.ml # Consumable types
│   │   ├── reload.ml    # Reload batch types
│   │   └── loadout.ml   # Loadout types
│   ├── repositories/    # Database access layer
│   │   ├── firearm_repo.ml
│   │   ├── gear_repo.ml
│   │   ├── checkout_repo.ml
│   │   ├── consumable_repo.ml
│   │   ├── reload_repo.ml
│   │   └── loadout_repo.ml
│   ├── services/       # Business logic
│   │   ├── checkout_service.ml
│   │   ├── loadout_service.ml
│   │   ├── maintenance_service.ml
│   │   └── import_export_service.ml
│   └── database.ml     # Database connection and schema
├── test/
│   └── test_gearTracker_ml.ml  # Unit tests
├── gearTracker-ml.opam   # Package definition
└── dune-project         # Dune project file
```

## License

MIT License
# gearTracker-ml
