#!/bin/bash
# ===========================================
# LAStools Container Build Script
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
IMAGE_PATH="$SCRIPT_DIR/images/lastools.sif"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --rebuild    Rebuild image if it exists (adds --force)"
    echo "  --help       Show this help"
}

BUILD_FORCE=""
if [ "${1:-}" = "--rebuild" ]; then
    BUILD_FORCE="--force"
elif [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

echo "[build] $IMAGE_PATH"
apptainer build --fakeroot $BUILD_FORCE "$IMAGE_PATH" "$SCRIPT_DIR/lastools.def"
echo "[done] built image at $IMAGE_PATH"