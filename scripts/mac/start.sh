#!/usr/bin/env bash
# start.sh - Start the ERPNext container, then its web server.
# Usage:  ./start.sh   (run: chmod +x start.sh  once)
set -euo pipefail

# Resolve docker-compose.yml relative to this script (scripts/mac/ -> repo root)
COMPOSE_FILE="$( cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd )/docker-compose.yml"
CONTAINER="erpnext_lightweight"

# Make sure Docker is installed and the daemon is actually running
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker Desktop first." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Please start Docker Desktop, wait until it is ready, then re-run this script." >&2
  exit 1
fi

echo "[1/2] Starting container..."
docker compose -f "$COMPOSE_FILE" up -d

# Wait until the container is actually running before exec-ing into it
tries=0
until [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = "true" ] || [ $tries -ge 30 ]; do
  sleep 1; tries=$((tries+1))
done

echo "[2/2] Starting web server (bench serve, detached)..."
docker exec -d "$CONTAINER" bash -lc "cd /home/frappe/frappe-bench && exec bench serve --port 8000 >> logs/serve.log 2>&1"

echo ""
echo "Done. Open http://test.localhost:8000  (Administrator / erpadmindb)"
