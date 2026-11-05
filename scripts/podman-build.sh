#!/bin/bash

set -euo pipefail

# Locate project directories
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Image configuration
IMAGE="localhost/containers-capstone"
VERSION="${1:-1.0.0}"

echo "=================================="
echo "       Podman Image Build"
echo "=================================="

# Verify Containerfile exists
if [[ ! -f "$PROJECT_DIR/Containerfile" ]]; then
    echo "[ERROR] Containerfile not found."
    exit 1
fi

echo ""
echo "Building image using Containerfile..."

podman build \
    -f "$PROJECT_DIR/Containerfile" \
    -t "$IMAGE:$VERSION" \
    "$PROJECT_DIR"

echo ""
echo "=================================="
echo " Build completed successfully!"
echo "=================================="

echo "Image: $IMAGE:$VERSION"

podman images "$IMAGE"
