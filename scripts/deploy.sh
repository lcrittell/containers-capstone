#!/bin/bash

set -euo pipefail

# Locate the project directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

echo "Starting Docker Compose deployment..."

# Start containers using existing images
sudo docker compose -f "$SCRIPT_DIR/docker-compose.yaml" up -d --no-build --remove-orphans

echo ""
echo "Deployment status:"
sudo docker compose -f "$SCRIPT_DIR/docker-compose.yaml" ps

echo ""
echo "Deployment completed successfully!"
