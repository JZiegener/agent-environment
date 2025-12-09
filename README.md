# Langfuse Local Development Environment

> A minimal Docker‑Compose stack that bundles all of the runtime services required by Langfuse.  It is designed to get the full stack up and running **quickly** for developers or CI pipelines.

---

## 👋 Overview

| Service | Image | Port mapping | Purpose |
|---|---|---|---|
| `langfuse-worker` | `docker.io/langfuse/langfuse-worker:3` | `127.0.0.1:3030:3030` | Background job processor & ingestion helper.
| `langfuse-web` | `docker.io/langfuse/langfuse:3` | `3000:3000` | Web UI and API.
| `postgres` | `docker.io/postgres:${POSTGRES_VERSION:-17}` | `127.0.0.1:5432:5432` | Relational database.
| `clickhouse` | `docker.io/clickhouse/clickhouse-server` | `127.0.0.1:8123:8123`, `127.0.0.1:9000:9000` | Columnar database used for telemetry data.
| `minio` | `cgr.dev/chainguard/minio` | `9090:9000`, `127.0.0.1:9091:9091` | S3‑compatible object storage.
| `redis` | `docker.io/redis:7` | `127.0.0.1:6379:6379` | Cache & message queue.

All services are wired together via Docker Compose.  For convenience the `reset.sh` script does a full clean‑run of the stack.

---

## 🛠️ Prerequisites

- Docker Engine (>= 20.10) with Docker‑Compose V2.
- Bash (for the helper scripts).

No additional runtime or dependency is required – the stack is completely self‑contained.

---

## 🚀 Getting Started

1. **Clone the repo** (or copy this directory) and step into it:
   ```bash
   git clone <repo‑url>
   cd agent-environment
   ```

2. **Generate a fresh `.env` file**.  The `generate-env.sh` script copies `.env.example` and populates all required secrets randomly.
   ```bash
   ./generate-env.sh
   ```
   > The script produces an `.env` file in the repository root.  It will also create a random RSA key pair for the Langfuse project and embed the public/private key in the file.

3. **Start the stack**.
   ```bash
   docker compose up -d --wait
   ```
   The `--wait` flag makes Compose pause until all services are ready.  After that you can access the UI at [http://localhost:3000](http://localhost:3000).

4. **Verify** – Open a new terminal and run: `docker compose ps` to see all containers are `Up`.

---

## 🧹 Resetting the Stack

If you need a clean slate (e.g. after a config change or to wipe test data), run the provided helper:
```bash
./reset.sh
```
This performs the following steps:
1. Stops and removes all existing containers.
2. Deletes associated Docker volumes.
3. Removes the current `.env` file (if present).
4. Generates a fresh `.env` file.
5. Brings the services back up in detached mode.

---

## ⚙️ Customizing the Environment

### Environment Variables

The `.env.example` file documents all supported variables.  Copy it to `.env` or let `generate-env.sh` do that for you.  Key variables include:

| Variable | Purpose |
|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | PostgreSQL credentials. |
| `REDIS_AUTH` | Password for Redis. |
| `NEXTAUTH_SECRET` | Secret used by Next‑Auth for session signing. |
| `SALT` & `ENCRYPTION_KEY` | Cryptographic salts used internally. |
| `LANGFUSE_INIT_*` | Project and org identifiers for first‑time bootstrap. |
| `MINIO_ROOT_PASSWORD` | Password for the MinIO bucket manager. |
| `CLICKHOUSE_PASSWORD` | Password for ClickHouse. |
| `LANGFUSE_S3_*` | S3/Bucket configuration for uploads and exports. |
| `TELEMETRY_ENABLED` | Toggle telemetry. |

> **Tip:** Open the `.env.example` and comment‑out any placeholder values you plan to set manually.  The Docker compose file reads the environment variables with the `${VAR:-default}` syntax, so defaults survive if you leave a key empty.

### Port Mapping

The stack exposes only the following **host ports**:
- `3000` – The web UI.
- `3030` – Worker API (useful for debugging / status).
- `9090` – MinIO S3 endpoint.
- `9091` – MinIO console.

All other services listen on `127.0.0.1` only, so they are not exposed to the host network.

---

## 🔌 Networking & Connectivity

All containers share the same Docker network as defined in `docker-compose.yaml`.  Services reference each other by the short names (`postgres`, `redis`, `clickhouse`, `minio`).  The web UI automatically resolves those names via Docker DNS.

Example DNS lookup inside the web container:
```bash
docker compose exec langfuse-web nslookup postgres
````

---

## 📦 Useful CLI commands

```bash
# Show container logs
docker compose logs -f

# Stop everything
docker compose down

# Remove volumes (danger!)
docker compose down -v

# Rebuild images (if you change the Dockerfile)
docker compose up --build
```

---

## 📚 Further Reading

- [Langfuse documentation](https://langfuse.com/docs) – full stack explanation and feature set.
- [MinIO official docs](https://min.io/docs)

---

## 📄 License

This repository is provided under the MIT License.  See the bundled `LICENSE` file for details.
