#!/bin/bash

set -euo pipefail

POD_NAME="containers-capstone-pod"

echo "=================================="
echo "       Podman Cleanup"
echo "=================================="

# Check whether the pod exists
if podman pod inspect "$POD_NAME" >/dev/null 2>&1; then
    echo ""
    echo "Removing Podman pod..."

    podman pod rm -f "$POD_NAME"

    echo ""
    echo "[SUCCESS] Podman pod removed."
else
    echo ""
    echo "[INFO] No existing Podman pod found."
fi

echo ""
echo "Persistent volumes and images have been preserved."
echo ""
echo "Cleanup completed!"
