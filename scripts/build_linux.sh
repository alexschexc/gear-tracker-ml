#!/bin/bash
# build_linux.sh - Build GearTracker for Linux

set -e

echo "=== GearTracker Linux Build Script ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
echo "Checking dependencies..."
command -v opam >/dev/null 2>&1 || { echo -e "${RED}opam is required but not installed${NC}"; exit 1; }
command -v dune >/dev/null 2>&1 || { echo -e "${RED}dune is required but not installed${NC}"; exit 1; }

# Install dependencies
echo
echo "Installing OCaml dependencies..."
opam install -y . --deps-only
opam install -y lablgtk3

# Build
echo
echo "Building GearTracker..."
eval $(opam env)
dune build --profile release

# Strip binaries
echo
echo "Optimizing binaries..."
strip _build/default/bin/gearTracker-ml 2>/dev/null || true
strip _build/default/bin/gearTracker-ml-gui 2>/dev/null || true

# Show results
echo
echo -e "${GREEN}Build complete!${NC}"
echo
echo "Binaries:"
ls -lh _build/default/bin/

echo
echo "To run:"
echo "  ./_build/default/bin/gearTracker-ml-gui"
