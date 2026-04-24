#!/bin/bash
# ===========================================
# city4cfd Build Script
# ===========================================
#
# Builds the city4cfd SIF image by pulling from
# the pre-built Docker image.
#
# Usage:
#   ./build.sh              # Check if image exists, build if missing
#   ./build.sh --check     # Same as above
#   ./build.sh --rebuild   # Force rebuild from scratch
#   ./build.sh --pull      # Force pull from Docker Hub
#   ./build.sh --help      # Show this help
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="city4cfd.sif"
IMAGE_PATH="$SCRIPT_DIR/images/$IMAGE_NAME"
DEF_FILE="$SCRIPT_DIR/city4cfd.def"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
Usage: ./build.sh [OPTIONS]

Build city4cfd SIF image from pre-built Docker image.

Options:
    --check     Check if image exists, build only if missing (default)
    --rebuild   Force rebuild from scratch (removes existing image)
    --pull      Force pull from Docker Hub (ignores local cache)
    --help      Show this help message

Examples:
    ./build.sh              # Auto-build if missing
    ./build.sh --check      # Same as above
    ./build.sh --rebuild    # Force rebuild
    ./build.sh --pull       # Force pull latest

Image Location:
    $IMAGE_PATH
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

pull_image() {
    info "Pulling city4cfd image from Docker Hub..."
    apptainer pull "$IMAGE_PATH" docker://tudelft3d/city4cfd:latest
    info "Image saved to: $IMAGE_PATH"
}

build_image() {
    mkdir -p "$SCRIPT_DIR/images"
    pull_image
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
        info "Pull requested..."
        pull_image
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