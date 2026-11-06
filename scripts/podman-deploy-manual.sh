#!/bin/bash

set -euo pipefail

#Create volume
podman volume inspect capstone-pgdata >/dev/null 2>&1 || podman volume create capstone-pgdata

#Create Network

#Create pod
podman pod create --name containers-capstone-pod --publish 5003:5000

PROJECT_DIR="$(pwd)"
ls -l "$PROJECT_DIR/postgres-init"

#Create db container
podman run -d \
    --name containers-capstone-pod-capstone-db  \
    --pod containers-capstone-pod \
    -e POSTGRES_USER=app \
    -e POSTGRES_PASSWORD=secret \
    -e POSTGRES_DB=mydb \
    --mount type=volume,src=capstone-pgdata,target=/var/lib/postgresql/data \
    --mount type=bind,src="$PROJECT_DIR/postgres-init",target=/docker-entrypoint-initdb.d,ro=true \
    docker.io/library/postgres:16-alpine

#Create app container
podman run -d \
    --name containers-capstone-pod-capstone-web \
    --pod containers-capstone-pod \
    -e DATABASE_URL=postgresql://app:secret@127.0.0.1:5432/mydb \
    quay.io/lccrittell/containers-capstone:$1
