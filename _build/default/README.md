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

### Prerequisites

- OCaml 5.0+
- opam (OCaml package manager)
- GTK+ 3 (for GUI)
- SQLite3

### Quick Build

```bash
# Build the library and CLI
dune build

# Run tests
dune test

# Run the CLI
dune exec -- gearTracker-ml

# Run the GUI
dune exec -- gearTracker-ml-gui
```

### Cross-Platform Builds

This project supports building for Linux, macOS, and Windows.

#### Linux

```bash
# Standard build
./scripts/build_linux.sh

# Or manually:
opam install -y . --deps-only
opam install -y lablgtk3
dune build --profile release
```

#### macOS

```bash
# Install dependencies
brew install opam gtk+3 sqlite3

# Setup opam
opam init --disable-sandboxing
opam install -y . --deps-only
opam install -y lablgtk3

# Build
dune build --profile release

# Create app bundle (optional)
./scripts/build_macos_app.sh
```

#### Windows (Cross-compile from Linux)

```bash
# Install MinGW cross-compiler
sudo apt-get install mingw-w64

# Setup Windows opam repository
opam repository add windows https://github.com/ocaml-cross/opam-cross-windows.git

# Install Windows toolchain
opam install -y ocaml-windows ocaml-windows-mingw64

# Build
dune build --profile release --workspace dune-workspace.windows
```

### CI/CD Builds

GitHub Actions workflows are configured to automatically build for all platforms:

- `.github/workflows/build-linux.yml` - Linux binaries and AppImage
- `.github/workflows/build-macos.yml` - macOS app bundle and DMG
- `.github/workflows/build-windows.yml` - Windows executables

Builds are triggered on pushes to `main` and tags starting with `v`.

## Project Structure

```
gearTracker-ml/
├── bin/
│   ├── main.ml          # CLI entry point
│   ├── cli.ml           # CLI interface
│   └── gui.ml           # GTK3 GUI
├── lib/
│   ├── core.ml          # Core module exports
│   ├── gearTracker_ml.ml # Top-level library module
│   ├── id.ml            # ID type
│   ├── timestamp.ml     # Timestamp utilities
│   ├── error.ml         # Error types and handling
│   ├── enums.ml         # Enumeration types
│   ├── firearm.ml       # Firearm type
│   ├── gear.ml          # Gear, NFA items, attachments
│   ├── checkout.ml      # Checkout and maintenance types
│   ├── consumable.ml    # Consumable types
│   ├── reload.ml        # Reload batch types
│   ├── loadout.ml       # Loadout types
│   ├── database.ml      # Database connection and schema
│   ├── validation.ml    # Validation utilities
│   ├── ImportExport.ml  # CSV import/export
│   ├── FirearmRepo.ml   # Firearm repository
│   ├── GearRepo.ml      # Gear repository
│   ├── ConsumableRepo.ml # Consumable repository
│   ├── CheckoutRepo.ml  # Checkout repository
│   ├── ReloadRepo.ml    # Reload repository
│   ├── LoadoutRepo.ml   # Loadout repository
│   ├── AttachmentRepo.ml # Attachment repository
│   ├── NFAItemRepo.ml   # NFA item repository
│   ├── TransferRepo.ml  # Transfer repository
│   ├── CheckoutService.ml # Checkout business logic
│   ├── LoadoutService.ml  # Loadout business logic
│   └── MaintenanceService.ml # Maintenance business logic
├── scripts/
│   ├── build_linux.sh   # Linux build script
│   ├── sample_data.ml   # Sample data generator
│   └── test_import_export_simple.ml # Import/export tests
├── test/
│   └── run_tests.ml     # Unit tests
├── .github/workflows/   # CI/CD workflows
│   ├── build-linux.yml
│   ├── build-macos.yml
│   └── build-windows.yml
├── gearTracker-ml.opam  # Package definition
├── dune-project         # Dune project file
└── dune-workspace       # Dune workspace config
```

## License

MIT License
# gearTracker-ml
