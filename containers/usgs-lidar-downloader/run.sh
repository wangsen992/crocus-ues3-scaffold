#!/bin/bash
# ===========================================
# USGS LIDAR Downloader Run Script
# ===========================================
#
# Downloads LIDAR tiles from USGS 3DEP via TNM Access API
#
# Usage:
#   ./run.sh --bbox xmin ymin xmax ymax --dry-run
#   ./run.sh --bbox xmin ymin xmax ymax --download --outdir /data/downloads
#   ./run.sh --bbox -87.65 41.87 -87.62 41.89 --download --outdir /data/lidar
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

IMAGE_PATH="$SCRIPT_DIR/images/usgs-lidar-downloader.sif"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

show_help() {
    cat << EOF
Usage: $0 --bbox xmin ymin xmax ymax [options]

Download LIDAR tiles from USGS 3DEP TNM Access API.

Options:
  --bbox xmin ymin xmax ymax  Bounding box coordinates (WGS84)
  --dry-run                    Show tiles without downloading
  --download                   Actually download the tiles
  --outdir PATH                Output directory (default: /data/downloads)
  --ql LEVEL                   Quality level filter (1, 2, or empty for any)

Examples:
  $0 --bbox -87.65 41.87 -87.62 41.89 --dry-run
  $0 --bbox -87.65 41.87 -87.62 41.89 --download --outdir /data/lidar
  $0 --bbox -87.65 41.87 -87.62 41.89 --download --outdir /data/lidar --ql 1

Configuration:
  Set CROCUS_ROOT environment variable to point to your project root:
  e.g., CROCUS_ROOT=/path/to/CROCUS-UES3 ./run.sh --bbox ... --download

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

info "Running USGS LIDAR Downloader..."
info "Project root: $PROJECT_ROOT"
apptainer run $BINDINGS "$IMAGE_PATH" "$@"