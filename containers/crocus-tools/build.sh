#!/bin/bash
# ===========================================
# crocus-tools Build Script
# ===========================================
#
# Builds the crocus-tools SIF image from the definition file.
# Downloads the crocus-tools source from GitHub at build time.
#
# Usage:
#   ./build.sh              # Check if image exists, build if missing
#   ./build.sh --check     # Same as above
#   ./build.sh --rebuild   # Force rebuild from scratch
#   ./build.sh --pull      # Pull latest source and rebuild
#   ./build.sh --help      # Show this help
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="crocus-tools.sif"
IMAGE_PATH="$SCRIPT_DIR/images/$IMAGE_NAME"
DEF_FILE="$SCRIPT_DIR/python.def"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
Usage: ./build.sh [OPTIONS]

Build crocus-tools SIF image from definition file.

Options:
    --check     Check if image exists, build only if missing (default)
    --rebuild   Force rebuild from scratch (removes existing image)
    --pull      Pull latest container definition and rebuild
    --help      Show this help message

Examples:
    ./build.sh              # Auto-build if missing
    ./build.sh --check      # Same as above
    ./build.sh --rebuild    # Force rebuild
    ./build.sh --pull       # Pull latest def and rebuild

Image Location:
    $IMAGE_PATH

Definition File:
    $DEF_FILE
EOF
}

check_image() {
    if [ -f "$IMAGE_PATH" ]; then
        info "Image found: $IMAGE_PATH"
        return 0
    else
        warn "Image not found: $IMAGE_PATH"
        return 1
    fi
}

build_image() {
    mkdir -p "$SCRIPT_DIR/images"
    info "Building crocus-tools image from $DEF_FILE..."
    apptainer build --fakeroot "$IMAGE_PATH" "$DEF_FILE"
    info "Image saved to: $IMAGE_PATH"
}

# ===========================================
# Main
# ===========================================

case "${1:-}" in
    --check|-c)
        check_image && exit 0 || { build_image; exit $?; }
        ;;
    --rebuild|-r)
        info "Rebuild requested..."
        rm -f "$IMAGE_PATH"
        build_image
        ;;
    --pull|-p)
        info "Pull requested (definition updated, rebuilding)..."
        build_image
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    "")
        check_image && exit 0 || { build_image; exit $?; }
        ;;
    *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac