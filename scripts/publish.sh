#!/bin/bash

set -euo pipefail

# Locate the scripts directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Locate the project root
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Image configuration
IMAGE="quay.io/lccrittell/containers-capstone"
VERSION="${1:-1.0.0}"

echo "=================================="
echo "    Quay Image Publishing"
echo "=================================="

# Verify version-specific image exists
if ! sudo docker image inspect "$IMAGE:$VERSION" >/dev/null 2>&1; then
    echo "[ERROR] Image $IMAGE:$VERSION was not found."
    echo "Run build.sh with this version before publishing."
    exit 1
fi

# Verify latest image exists
if ! sudo docker image inspect "$IMAGE:latest" >/dev/null 2>&1; then
    echo "[ERROR] Image $IMAGE:latest was not found."
    echo "Run build.sh before publishing."
    exit 1
fi

echo ""
echo "Publishing version $VERSION..."

sudo docker push "$IMAGE:$VERSION"

echo ""
echo "Publishing latest tag..."

sudo docker push "$IMAGE:latest"

echo ""
echo "=================================="
echo " Publishing completed!"
echo "=================================="
echo "Published images:"
echo "  $IMAGE:$VERSION"
echo "  $IMAGE:latest"
