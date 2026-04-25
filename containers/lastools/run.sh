#!/bin/bash
# ===========================================
# LAStools Run Script
# ===========================================
#
# Wrapper to run LAStools inside Apptainer container.
# Handles path bindings for data access.
#
# Usage:
#   ./run.sh laszip -i input.laz -o output.las
#   ./run.sh las2las -i input.laz -o output.las
#   ./run.sh --help
#   ./run.sh --shell
#
# Configuration:
#   Set CROCUS_ROOT env var to point to your project root
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root - configurable via CROCUS_ROOT env var
if [ -n "${CROCUS_ROOT}" ]; then
    PROJECT_ROOT="${CROCUS_ROOT}"
else
    PROJECT_ROOT="${SCRIPT_DIR}/../../.."
fi

IMAGE_PATH="$SCRIPT_DIR/images/lastools.sif"
OVERLAY_DIR="$SCRIPT_DIR/overlay"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

show_help() {
    cat << EOF
Usage: $0 <tool> [args]

Run LAStools inside Apptainer container.

Available tools: laszip, las2las, las2dem, lasgrid, lasinfo, lasmerge, lastile, lasview

Examples:
  $0 laszip -i input.laz -o output.las
  $0 las2las -i input.laz -o output.las --keep-class 2
  $0 --help
  $0 --shell

Configuration:
  Set CROCUS_ROOT environment variable to point to your project root:
  e.g., CROCUS_ROOT=/path/to/CROCUS-UES3 ./run.sh laszip -i input.laz -o output.las

Bindings:
  /data → CROCUS_ROOT
EOF
}

# Ensure overlay directory exists
mkdir -p "$OVERLAY_DIR"

if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} Image not found: $IMAGE_PATH"
    echo "Run ./build.sh first."
    exit 1
fi

BINDINGS="-B ${PROJECT_ROOT}:/data"

if [ "${1:-}" = "--help" ]; then
    show_help
    exit 0
fi

if [ "${1:-}" = "--shell" ]; then
    info "Starting interactive shell..."
    apptainer shell --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH"
else
    apptainer exec --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH" "$@"
fi