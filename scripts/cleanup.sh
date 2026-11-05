#!/bin/bash

set -euo pipefail

# Locate the scripts directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Locate the project root
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Move to the project root
cd "$PROJECT_DIR"

echo "=================================="
echo " Containers Capstone Cleanup"
echo "=================================="

# Verify Docker Compose configuration exists
if [[ ! -f docker-compose.yaml ]]; then
    echo "[ERROR] compose.yaml was not found in $PROJECT_DIR"
    exit 1
fi

echo "Stopping and removing containers..."
sudo docker compose down --remove-orphans

echo ""
echo "Cleanup completed successfully!"
echo ""
echo "Persistent volumes and Docker images have been preserved."
