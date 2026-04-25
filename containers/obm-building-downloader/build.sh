#!/bin/bash
# ===========================================
# OpenBuildingMap Downloader Build Script
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_PATH="$SCRIPT_DIR/images/obm-building-downloader.sif"

echo "[build] Building OpenBuildingMap Downloader container..."
echo "       Image: $IMAGE_PATH"

apptainer build --fakeroot "$IMAGE_PATH" "$SCRIPT_DIR/obm-building-downloader.def"

echo "[done] Built image at $IMAGE_PATH"