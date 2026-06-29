#!/usr/bin/env bash
# start.sh - Start the ERPNext stack.
# Equivalent to running `docker compose up -d` from the repo root.
# The container's entrypoint auto-detects first-install vs restart and runs `bench start`.
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

echo "Starting stack..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "Done. First-time install can take 5-15 minutes — watch progress with:"
echo "  docker compose -f \"$COMPOSE_FILE\" logs -f erpnext-dev"
echo "Then open http://test.localhost:8000  (Administrator / erpadmindb)"
