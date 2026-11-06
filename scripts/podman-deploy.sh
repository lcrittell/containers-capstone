#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

VOLUME_NAME="capstone-pgdata"

echo "Starting Podman deployment..."

# Create volume only if it doesn't already exist
if ! podman volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    echo "Creating PostgreSQL volume..."
    podman volume create "$VOLUME_NAME"
else
    echo "Reusing existing PostgreSQL volume..."
fi

# Get the actual volume mountpoint
VOLUME_PATH="$(podman volume inspect \
    --format '{{.Mountpoint}}' "$VOLUME_NAME")"

if [[ ! -d "$VOLUME_PATH" ]]; then
    echo "[ERROR] PostgreSQL volume directory not found: $VOLUME_PATH"
    exit 1
fi

# Generate YAML with resolved absolute paths
TMP_YAML="$(mktemp)"
trap 'rm -f "$TMP_YAML"' EXIT

sed \
    -e "s|%HOMEPATH%|$PROJECT_DIR|g" \
    -e "s|%PGDATA_PATH%|$VOLUME_PATH|g" \
    "$PROJECT_DIR/podman-pod.yaml" > "$TMP_YAML"

echo ""
echo "Deploying Podman configuration..."

podman play kube "$TMP_YAML"

echo ""
echo "Podman deployment completed!"
podman pod ps
podman ps
