#!/usr/bin/env bash
# ERPNext 16 lightweight bootstrap — runs as PID 1 inside the container.
#
# Decides between "first-time install" and "restart" based on the volume state,
# then runs `bench start` to keep web + socketio + worker + schedule + watch alive.
#
# Idempotent: safe to re-run. Skips any step whose output already exists.

set -euo pipefail

BENCH_DIR="/home/frappe/frappe-bench"
SITE_NAME="${SITE_NAME:-test.localhost}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-erpadmindb}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-16}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-16}"
REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

log() { printf '\n[entrypoint] %s\n' "$*"; }

wait_for_redis() {
  log "Waiting for redis at ${REDIS_HOST}:${REDIS_PORT} ..."
  local tries=0
  until (exec 3<>/dev/tcp/${REDIS_HOST}/${REDIS_PORT}) >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 60 ]; then
      log "ERROR: redis not reachable after 60s — aborting."
      exit 1
    fi
    sleep 1
  done
  exec 3>&- 2>/dev/null || true
  log "redis is reachable."
}

bench_init_if_needed() {
  if [ -d "${BENCH_DIR}/apps/frappe" ] && [ -f "${BENCH_DIR}/sites/common_site_config.json" ]; then
    log "Existing bench at ${BENCH_DIR} — skipping bench init."
    return
  fi

  log "Fresh volume detected. Running first-time bench init (5–15 min, downloads Frappe + ERPNext)..."
  cd /home/frappe
  bench init --skip-redis-config-generation --frappe-branch "${FRAPPE_BRANCH}" frappe-bench

  cd "${BENCH_DIR}"
  log "Fetching ERPNext (${ERPNEXT_BRANCH})..."
  bench get-app --branch "${ERPNEXT_BRANCH}" erpnext

  log "Pointing bench at redis sidecar..."
  bench set-config -g redis_cache    "redis://${REDIS_HOST}:${REDIS_PORT}/0"
  bench set-config -g redis_queue    "redis://${REDIS_HOST}:${REDIS_PORT}/1"
  bench set-config -g redis_socketio "redis://${REDIS_HOST}:${REDIS_PORT}/2"
}

site_create_if_needed() {
  cd "${BENCH_DIR}"
  if [ -d "sites/${SITE_NAME}" ] && [ -f "sites/${SITE_NAME}/site_config.json" ]; then
    log "Site '${SITE_NAME}' already exists — skipping site creation."
    return
  fi

  log "Creating site '${SITE_NAME}' (SQLite) and installing ERPNext..."
  bench new-site "${SITE_NAME}" \
    --db-type sqlite \
    --admin-password "${ADMIN_PASSWORD}" \
    --install-app erpnext

  bench --site "${SITE_NAME}" set-config developer_mode 1
  bench --site "${SITE_NAME}" clear-cache
  bench use "${SITE_NAME}"
}

main() {
  wait_for_redis
  bench_init_if_needed
  site_create_if_needed

  cd "${BENCH_DIR}"
  log "Bench ready. Starting all services (bench start)..."
  log "Open http://${SITE_NAME}:8000  (Administrator / ${ADMIN_PASSWORD})"
  exec bench start
}

main "$@"
