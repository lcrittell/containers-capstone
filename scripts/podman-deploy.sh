#!/bin/bash

set -euo pipefail

# Locate project directories
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Configuration
IMAGE="quay.io/lccrittell/containers-capstone"
VERSION="${1:-1.0.0}"
POSTGRES_IMAGE="docker.io/library/postgres:16-alpine"

POD_NAME="containers-capstone-pod"
DB_CONTAINER="capstone-db"
WEB_CONTAINER="capstone-web"
VOLUME="capstone-pgdata"

HOST_PORT="${HOST_PORT:-5003}"

DATABASE_URL="postgresql://app:secret@127.0.0.1:5432/mydb"

echo "=================================="
echo "       Podman Deployment"
echo "=================================="

# Verify initialization SQL exists
if [[ ! -f "$PROJECT_DIR/init.sql" ]]; then
    echo "[ERROR] init.sql was not found."
    exit 1
fi

# Pull required images
echo ""
echo "Pulling application image..."
podman pull "$IMAGE:$VERSION"

echo ""
echo "Pulling PostgreSQL image..."
podman pull "$POSTGRES_IMAGE"

# Remove existing pod if present
if podman pod inspect "$POD_NAME" >/dev/null 2>&1; then
    echo ""
    echo "Removing existing Podman pod..."
    podman pod rm -f "$POD_NAME"
fi

# Create persistent volume if it does not exist
if ! podman volume inspect "$VOLUME" >/dev/null 2>&1; then
    echo ""
    echo "Creating persistent database volume..."
    podman volume create "$VOLUME"
fi

# Create pod
echo ""
echo "Creating Podman pod..."

podman pod create \
    --name "$POD_NAME" \
    -p "$HOST_PORT:5000"

# Start PostgreSQL
echo ""
echo "Starting PostgreSQL..."

podman run -d \
    --pod "$POD_NAME" \
    --name "$DB_CONTAINER" \
    -e POSTGRES_USER=app \
    -e POSTGRES_PASSWORD=secret \
    -e POSTGRES_DB=mydb \
    -v "$VOLUME:/var/lib/postgresql/data" \
    -v "$PROJECT_DIR/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro" \
    "$POSTGRES_IMAGE"

# Wait for PostgreSQL to become ready
echo ""
echo "Waiting for PostgreSQL..."

DB_READY=false

for attempt in {1..30}; do
    if podman exec "$DB_CONTAINER" pg_isready -U app -d mydb >/dev/null 2>&1; then
        DB_READY=true
        break
    fi

    sleep 2
done

if [[ "$DB_READY" != true ]]; then
    echo "[ERROR] PostgreSQL failed to become ready."
    podman logs "$DB_CONTAINER"
    exit 1
fi

echo "[PASS] PostgreSQL is ready."

# Start Flask
echo ""
echo "Starting Flask application..."

podman run -d \
    --pod "$POD_NAME" \
    --name "$WEB_CONTAINER" \
    -e DATABASE_URL="$DATABASE_URL" \
    "$IMAGE:$VERSION"

echo ""
echo "=================================="
echo " Podman deployment completed!"
echo "=================================="

podman pod ps
podman ps

echo ""
echo "Application URL: http://localhost:$HOST_PORT"
