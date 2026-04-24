#!/bin/bash
# ===========================================
# crocus-tools Run Script
# ===========================================
#
# Wrapper script to run crocus Python tools inside Apptainer container.
# Source code is encapsulated inside the container image.
#
# Usage:
#   ./run.sh <args>           # Run with args
#   ./run.sh --help           # Show crocus help
#   ./run.sh --shell          # Interactive shell
#   ./run.sh --pip list       # Run pip command inside container
#
# Configuration:
#   Set CROCUS_ROOT env var to point to your project root
#   e.g., CROCUS_ROOT=/path/to/myproject ./run.sh crocus --help
#
# Bindings (data only, no source):
#   - Project root mounted to /data
#   - run/ directory mounted to /run
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

IMAGE_PATH="$SCRIPT_DIR/images/crocus-tools.sif"
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

Run crocus-tools inside Apptainer container.

Options:
    --help      Show this help message
    --shell    Start an interactive shell in the container
    --pip CMD  Run pip command (e.g., --pip list)

Configuration:
    Set CROCUS_ROOT environment variable to point to your project root:
    e.g., CROCUS_ROOT=/path/to/myproject ./run.sh crocus --help

Bindings (data only):
    /data  → CROCUS_ROOT (or CROCUS-UES3/)
    /run   → \$CROCUS_ROOT/run/ (simulation cases, rw)
    /cases → \$CROCUS_ROOT/cases/ (symlinks)

Note: Source code is encapsulated inside the container image.

Examples:
    ./run.sh --help
    ./run.sh crocus --help
    ./run.sh crocus city4cfd prep --case /data/cases/UIC ...
    ./run.sh --shell
    ./run.sh --pip list
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
    info "Starting interactive shell..."
    apptainer shell --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH"
elif [ "${1:-}" = "--pip" ]; then
    shift
    apptainer exec --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH" pip "$@"
else
    apptainer exec --overlay "$OVERLAY_DIR" $BINDINGS "$IMAGE_PATH" python -m crocus "$@"
fi