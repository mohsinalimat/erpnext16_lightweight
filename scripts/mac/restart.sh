#!/usr/bin/env bash
# restart.sh - Restart the ERPNext stack.
# Equivalent to running `docker compose restart` from the repo root.
# The container's entrypoint re-runs `bench start` automatically.
set -euo pipefail

COMPOSE_FILE="$( cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd )/docker-compose.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker Desktop first." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Please start Docker Desktop, then re-run this script." >&2
  exit 1
fi

echo "Restarting stack..."
docker compose -f "$COMPOSE_FILE" restart

echo ""
echo "Done. Open http://test.localhost:8000  (Administrator / erpadmindb)"
