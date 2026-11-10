#!/usr/bin/env bash
set -euo pipefail

# Pulls the current demo image, recreates the app and rolls back to the image
# that was running before if the new one does not answer /health. A digest that
# failed is quarantined, so the five-minute timer does not retry it in a loop
# and a later, different push is still deployed.

cd /opt/velomine

HEALTH_URL="${HEALTH_URL:-https://demo.velomine.eu/health}"
HEALTH_RESOLVE="${HEALTH_RESOLVE:-demo.velomine.eu:443:127.0.0.1}"
HEALTH_ATTEMPTS="${HEALTH_ATTEMPTS:-24}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-5}"
STATE_DIR="${STATE_DIR:-/opt/velomine/state}"
APP_CONTAINER="velomine-demo-app-1"

mkdir -p "$STATE_DIR"

log() { printf '%s %s\n' "$(date -Is)" "$*"; }

# Check through Caddy on the loopback interface, so a broken public path or DNS
# does not look like a broken image.
healthy() {
  curl -fsS --max-time 5 --resolve "$HEALTH_RESOLVE" "$HEALTH_URL" >/dev/null 2>&1
}

wait_healthy() {
  local i
  for ((i = 1; i <= HEALTH_ATTEMPTS; i++)); do
    healthy && return 0
    sleep "$HEALTH_INTERVAL"
  done
  return 1
}

repo_digest() {
  docker inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$1" 2>/dev/null || true
}

# A container has no RepoDigests; resolve its image ID first.
container_ref() {
  local image
  image="$(docker inspect --format '{{.Image}}' "$1" 2>/dev/null || true)"
  [ -n "$image" ] && repo_digest "$image"
}

image_ref() { sed -n 's/^VELOMINE_IMAGE=//p' .env | tail -1; }

previous="$(container_ref "$APP_CONTAINER")"
log "running:  ${previous:-none}"

docker compose pull --quiet app
pulled="$(repo_digest "$(image_ref)")"
log "registry: ${pulled:-unknown}"

if [ -f "$STATE_DIR/quarantined" ] && [ "$(cat "$STATE_DIR/quarantined")" = "$pulled" ]; then
  log "this image failed its health check before; waiting for a new build"
  exit 0
fi

if [ -n "$previous" ] && [ "$previous" = "$pulled" ]; then
  log "already running the current image"
  exit 0
fi

docker compose up --detach --remove-orphans app

if wait_healthy; then
  log "healthy: ${pulled}"
  rm -f "$STATE_DIR/quarantined"
  exit 0
fi

log "health check failed for ${pulled:-the pulled image}"
printf '%s\n' "$pulled" > "$STATE_DIR/quarantined"

if [ -z "$previous" ]; then
  log "no previous image to roll back to"
  exit 1
fi

log "rolling back to ${previous}"
VELOMINE_IMAGE="$previous" docker compose up --detach --remove-orphans app

if wait_healthy; then
  log "rolled back and healthy: ${previous}"
  exit 0
fi

log "rollback is not healthy either; the host needs attention"
exit 1
