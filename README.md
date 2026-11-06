# Containers Capstone

A small Flask REST API backed by PostgreSQL, deployed with Docker Compose and rootless Podman. The project focuses on container image creation, deployment, networking, persistent storage, Quay publishing, Bash automation, and operational testing.

## Architecture

| Deployment | Application port | Database connection | Persistent database storage |
|---|---:|---|---|
| Docker Compose | `5001` | `db:5432` | Docker named volume `pgdata` |
| Podman `play kube` | `5003` | `127.0.0.1:5432` | Podman volume `capstone-pgdata` |
| Podman native CLI | `5003` | `127.0.0.1:5432` | Podman volume `capstone-pgdata` |

Both Podman methods run Flask and PostgreSQL in one pod. The containers share a network namespace, so Flask connects to PostgreSQL through `127.0.0.1`. The Podman methods are alternatives: use one at a time because they share the same pod name and host port.

## Project files

```text
containers-capstone/
├── app/app.py
├── postgres-init/01-init.sql
├── scripts/
│   ├── build.sh                 # Docker image build and tags
│   ├── deploy.sh                # Docker Compose deployment
│   ├── validate.sh              # Docker validation
│   ├── cleanup.sh               # Docker cleanup
│   ├── publish.sh               # Push image tags to Quay
│   ├── podman-build.sh          # Build from Containerfile
│   ├── podman-deploy.sh         # Podman play kube deployment
│   ├── podman-cleanup.sh        # Podman play kube cleanup
│   └── podman-deploy-manual.sh  # Native Podman CLI deployment
├── Dockerfile
├── Containerfile
├── docker-compose.yaml
├── podman-pod.yaml
├── menu.sh
└── README.md
```

The Podman validation/cleanup scripts should match the deployment method being tested. `podman play kube` generates pod-prefixed container names; the native CLI script explicitly names its containers `capstone-db` and `capstone-web`.

## Prerequisites

- Ubuntu Linux with Docker Engine, the Docker Compose plugin, and Podman installed.
- `curl` for API testing.
- A Quay account and repository: `quay.io/lccrittell/containers-capstone`.
- Rootless Podman configured for the regular Linux user.

Check the tools and rootless mode:

```bash
docker --version
docker compose version
podman --version
podman info --format '{{.Host.Security.Rootless}}'
```

Use Docker with `sudo` if that is how Docker is configured on the VM. Run Podman as your regular user, without `sudo`; rootful and rootless Podman use separate image, container, and volume stores.

## Management menu

From the project root:

```bash
chmod +x menu.sh scripts/*.sh
./menu.sh
```

The menu runs the project's Docker, Quay, and Podman scripts. Each script can also be run directly from the repository root.

## Docker workflow

### Build and deploy

```bash
./scripts/build.sh 1.0.0
./scripts/deploy.sh
```

The build script builds the Flask image and tags it for Quay. The deploy script starts the services defined in `docker-compose.yaml` without rebuilding the image.

Check status and logs:

```bash
sudo docker compose ps
sudo docker compose logs --tail=100
```

Validate the deployment:

```bash
./scripts/validate.sh
curl -i http://localhost:5001/health
curl -i http://localhost:5001/items
```

### Publish to Quay

Authenticate Docker, then build and publish the desired version:

```bash
sudo docker login quay.io
./scripts/build.sh 1.0.0
./scripts/publish.sh 1.0.0
```

The script publishes both `1.0.0` and `latest` tags. Use a new version (for example, `1.0.1`) for a subsequent release. Do not store registry passwords or tokens in scripts or Git.

### Clean up

```bash
./scripts/cleanup.sh
```

This removes the Compose containers and network but preserves the database volume. Do not add `-v` / `--volumes` unless you intend to delete the database.

## Podman workflows

Podman is used rootless, without `sudo`. Both methods below use the same Quay application image, PostgreSQL image, pod name, port, and persistent volume. They are two ways to create the same deployment—not two deployments to run simultaneously.

### Build an image with the Containerfile

To demonstrate Podman's image-building workflow independently of Docker:

```bash
./scripts/podman-build.sh 1.0.0
podman images
```

This creates a locally tagged image. The Podman deployment workflows below use the Quay image to demonstrate that an image built and published with Docker can also run under Podman.

### Option 1: Kubernetes-style YAML with `podman play kube`

This method defines the pod and its containers in `podman-pod.yaml` and applies the file with `podman play kube`.

```bash
podman login quay.io                 # only needed for a private repository
./scripts/podman-deploy.sh
```

The deployment script resolves the `%HOMEPATH%` and `%PGDATA_PATH%` placeholders, creates `capstone-pgdata` if needed, and passes the generated YAML to Podman. The YAML defines the PostgreSQL and Flask containers, shared pod networking, port `5003`, the database volume, and the read-only initialization-script mount.

Remove this deployment with:

```bash
./scripts/podman-cleanup.sh
```

The cleanup script uses the same resolved YAML with `podman play kube --down`. The named database volume is kept.

### Option 2: Native Podman CLI commands

This method creates the same pod explicitly with `podman pod create` and starts each container with `podman run`:

```bash
./scripts/podman-deploy-manual.sh
```

The script creates the pod `containers-capstone-pod`, publishes host port `5003`, and runs:

- PostgreSQL as `capstone-db`, using `capstone-pgdata` for database files.
- Flask as `capstone-web`, using the Quay image and `DATABASE_URL` set to `127.0.0.1:5432`.

The database uses two different mount types:

```bash
--mount type=volume,src=capstone-pgdata,target=/var/lib/postgresql/data
--mount type=bind,src="$PROJECT_DIR/postgres-init",target=/docker-entrypoint-initdb.d,ro=true
```

The first is a Podman-managed named volume for persistent database storage. The second bind-mounts the host directory containing SQL initialization scripts.

To remove the native CLI deployment while preserving its volume:

```bash
podman pod rm -f containers-capstone-pod
```

If a dedicated manual cleanup script is added, it should perform this operation. Do not use `podman play kube --down` to remove a pod created by the native CLI method.

### Validate Podman

Run the Podman validation script associated with the deployment method currently in use. For the native CLI deployment, container names are `capstone-db` and `capstone-web`. For `podman play kube`, Podman generates pod-prefixed names.

Useful checks:

```bash
podman pod ps
podman ps --pod
podman logs capstone-db
podman logs capstone-web
podman exec capstone-db pg_isready -U app -d mydb
curl -i http://localhost:5003/health
curl -i http://localhost:5003/items
```

## Flask API

Set the URL for the deployment being tested:

```bash
BASE_URL=http://localhost:5001  # Docker Compose
# BASE_URL=http://localhost:5003  # Podman
```

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/` | Confirm Flask responds |
| `GET` | `/health` | Check database connectivity |
| `GET` | `/items` | List records |
| `POST` | `/items` | Create a record |
| `DELETE` | `/items/<id>` | Delete a record |

Examples:

```bash
curl -i "$BASE_URL/"
curl -i "$BASE_URL/health"
curl -i "$BASE_URL/items"

curl -i -X POST "$BASE_URL/items" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Capstone Demonstration"}'

curl -i -X DELETE "$BASE_URL/items/1"  # replace 1 with the record ID
```

A healthy `/health` response is HTTP `200` with `{"database":"connected","status":"healthy"}`. If Flask cannot reach PostgreSQL, it returns HTTP `503`.

## Operations and troubleshooting

### Logs and status

```bash
# Docker
sudo docker compose ps
sudo docker compose logs --tail=100

# Podman
podman pod ps
podman ps --pod
podman logs capstone-db
podman logs capstone-web
```

### Verify persistence

Create a record through `/items`, clean up the containers/pod using the normal cleanup procedure, redeploy, and query `/items` again. The record should remain because normal cleanup preserves the database volume.

Inspect the Podman volume:

```bash
podman volume inspect capstone-pgdata
```

PostgreSQL initialization scripts in `postgres-init/` run only when the database data directory is first initialized. Changes to the SQL files are not automatically applied to an existing database.

### Reset database data (destructive)

Only do this when you intentionally want to erase the database. Back up any data you need first.

```bash
# Docker Compose: removes Compose-managed volumes
sudo docker compose down --volumes

# Podman: remove the pod first, then its named volume
podman pod rm -f containers-capstone-pod
podman volume rm capstone-pgdata
```
