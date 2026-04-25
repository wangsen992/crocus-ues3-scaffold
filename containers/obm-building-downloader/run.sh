#!/bin/bash
# ===========================================
# OpenBuildingMap Downloader Run Script
# ===========================================
#
# Downloads building footprints from OpenBuildingMap public tiles
#
# Usage:
#   ./run.sh --bbox xmin ymin xmax ymax --out /data/buildings.geojson
#   ./run.sh --bbox xmin ymin xmax ymax --dry-run
#   ./run.sh --bbox -87.65 41.87 -87.62 41.89 --out /data/buildings.geojson
#
# Configuration:
#   Set CROCUS_ROOT env var to point to your project root
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${CROCUS_ROOT}" ]; then
    PROJECT_ROOT="${CROCUS_ROOT}"
else
    PROJECT_ROOT="${SCRIPT_DIR}/../../.."
fi

IMAGE_PATH="$SCRIPT_DIR/images/obm-building-downloader.sif"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

show_help() {
    cat << EOF
Usage: $0 --bbox xmin ymin xmax ymax --out output.geojson [options]

Download building footprints from OpenBuildingMap.

Options:
  --bbox xmin ymin xmax ymax  Bounding box coordinates (WGS84)
  --out PATH                   Output GeoJSON file path
  --dry-run                    Show tiles without downloading/exporting

Examples:
  $0 --bbox -87.65 41.87 -87.62 41.89 --out /data/buildings.geojson --dry-run
  $0 --bbox -87.65 41.87 -87.62 41.89 --out /data/buildings.geojson

Configuration:
  Set CROCUS_ROOT environment variable to point to your project root:
  e.g., CROCUS_ROOT=/path/to/CROCUS-UES3 ./run.sh --bbox ... --out ...

Bindings:
  /data → CROCUS_ROOT
EOF
}

if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} Image not found: $IMAGE_PATH"
    echo "Run ./build.sh first."
    exit 1
fi

if [ "${1:-}" = "--help" ]; then
    show_help
    exit 0
fi

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

BINDINGS="-B ${PROJECT_ROOT}:/data"

info "Running OpenBuildingMap Downloader..."
info "Project root: $PROJECT_ROOT"
apptainer run $BINDINGS "$IMAGE_PATH" "$@"