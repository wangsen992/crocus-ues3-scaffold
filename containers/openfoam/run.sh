#!/bin/bash
# ===========================================
# openfoam Run Script
# ===========================================
#
# Wrapper script to run OpenFOAM inside Apptainer container.
# Source code is encapsulated inside the container image.
# Handles path bindings and overlay for persistence.
#
# Usage:
#   ./run.sh <args>           # Run OpenFOAM command with args
#   ./run.sh --help           # Show this help
#   ./run.sh --shell          # Interactive shell (sources OpenFOAM bashrc)
#
# Configuration:
#   Set CROCUS_ROOT env var to point to your project root
#   e.g., CROCUS_ROOT=/path/to/myproject ./run.sh foamVersion
#
# Bindings (data only, no source):
#   - Project root mounted to /data
#   - run/ directory mounted to /run (simulation cases)
#   - cases/ directory mounted to /cases
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root - configurable via CROCUS_ROOT env var
if [ -n "${CROCUS_ROOT}" ]; then
    PROJECT_ROOT="${CROCUS_ROOT}"
else
    # Default: assume scaffold is inside CROCUS-UES3 project
    PROJECT_ROOT="${SCRIPT_DIR}/../../CROCUS-UES3"
fi

IMAGE_PATH="$SCRIPT_DIR/images/openfoam.sif"
OVERLAY_DIR="$SCRIPT_DIR/overlay"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# Ensure overlay directory exists
mkdir -p "$OVERLAY_DIR"

show_help() {
    cat << EOF
Usage: ./run.sh [OPTIONS] [ARGS]

Run OpenFOAM inside Apptainer container.

Options:
    --help      Show this help message
    --shell    Start an interactive shell (sources OpenFOAM environment)

Configuration:
    Set CROCUS_ROOT environment variable to point to your project root:
    e.g., CROCUS_ROOT=/path/to/myproject ./run.sh foamVersion

Bindings (data only):
    /data  → CROCUS_ROOT (or CROCUS-UES3/)
    /run   → \$CROCUS_ROOT/run/ (simulation cases, rw)
    /cases → \$CROCUS_ROOT/cases/ (symlinks)

Note: Source code is encapsulated inside the container image.

Examples:
    ./run.sh --help
    ./run.sh foamVersion
    ./run.sh ./Allrun
    ./run.sh --shell
EOF
}

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    error "Image not found: $IMAGE_PATH"
    echo "Run ./build.sh first to build the image."
    exit 1
fi

# Verify project root exists
if [ ! -d "$PROJECT_ROOT" ]; then
    error "Project root not found: $PROJECT_ROOT"
    echo "Set CROCUS_ROOT environment variable to point to your project."
    exit 1
fi

# Bindings - ONLY data paths, NO source code mount
BINDINGS="-B ${PROJECT_ROOT}:/data"
BINDINGS="$BINDINGS -B ${PROJECT_ROOT}/run:/run:rw"
BINDINGS="$BINDINGS -B ${PROJECT_ROOT}/cases:/cases"

# ===========================================
# Main
# ===========================================

if [ "${1:-}" = "--help" ]; then
    show_help
    exit 0
fi

if [ "${1:-}" = "--shell" ]; then
    info "Starting OpenFOAM shell..."
    apptainer shell --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH"
else
    apptainer exec --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH" "$@"
fi