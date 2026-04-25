#!/bin/bash
# ===========================================
# USGS LIDAR Downloader Build Script
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_PATH="$SCRIPT_DIR/images/usgs-lidar-downloader.sif"

echo "[build] Building USGS LIDAR Downloader container..."
echo "       Image: $IMAGE_PATH"

apptainer build --fakeroot --force "$IMAGE_PATH" "$SCRIPT_DIR/usgs-lidar-downloader.def"

echo "[done] Built image at $IMAGE_PATH"