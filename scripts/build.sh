#!/bin/bash

set -euo pipefail

# Image configuration
IMAGE="quay.io/lccrittell/containers-capstone"
VERSION="${1:-1.0.0}"

echo "Building Flask application..."

sudo docker compose build web

echo "Tagging image..."

sudo docker tag containers-capstone-web:latest "$IMAGE:$VERSION"
sudo docker tag containers-capstone-web:latest "$IMAGE:latest"

echo "Build completed successfully!"
echo "Created tags:"
echo "  $IMAGE:$VERSION"
echo "  $IMAGE:latest"
