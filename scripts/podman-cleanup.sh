#!/bin/bash

set -euo pipefail

# Locate project directories
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Configuration
POD_NAME="containers-capstone-pod"
VOLUME_NAME="capstone-pgdata"

echo "=================================="
echo "       Podman Cleanup"
echo "=================================="

# Check whether the pod exists
if ! podman pod inspect "$POD_NAME" >/dev/null 2>&1; then
    echo "[INFO] No existing Podman pod found."
    exit 0
fi

# Retrieve existing PostgreSQL volume mountpoint
if ! VOLUME_PATH=$(podman volume inspect \
    --format '{{.Mountpoint}}' "$VOLUME_NAME"); then
    echo "[ERROR] PostgreSQL volume could not be located."
    exit 1
fi

# Generate temporary YAML with resolved paths
TMP_YAML="$(mktemp)"
trap 'rm -f "$TMP_YAML"' EXIT

sed \
    -e "s|%HOMEPATH%|$PROJECT_DIR|g" \
    -e "s|%PGDATA_PATH%|$VOLUME_PATH|g" \
    "$PROJECT_DIR/podman-pod.yaml" > "$TMP_YAML"

echo ""
echo "Stopping and removing Podman deployment..."

podman play kube --down "$TMP_YAML"

echo ""
echo "[SUCCESS] Podman deployment removed."

echo ""
echo "Remaining Podman pods:"
podman pod ps

echo ""
echo "PostgreSQL volume preserved: $VOLUME_NAME"
echo "Cleanup completed!"
