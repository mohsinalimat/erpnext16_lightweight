#!/usr/bin/env bash
# stop.sh - Stop the ERPNext container (and the web server inside it). Data is kept.
set -euo pipefail

# Resolve docker-compose.yml relative to this script (scripts/mac/ -> repo root)
COMPOSE_FILE="$( cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd )/docker-compose.yml"

echo "Stopping container (web server stops with it; data is safe in the volume)..."
docker compose -f "$COMPOSE_FILE" stop

echo "Stopped."
