#!/usr/bin/env bash
# Runs one environment's image pointers: pulls ghcr.io/zenkraker/velomine-{server,web}:<env>, which the Deploy workflow
# moves together, recreates the pair and rolls both back to the digests that were running before if the environment
# does not answer /health through Traefik. A pair that failed is quarantined, so the timer does not retry it every
# minute; a later, different pair is still deployed. Started by velomine-update@<env>.timer.
#
#   update.sh <env>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

env="${1:-}"
require_env "$env"

state_dir="$VELOMINE_DIR/$env/state"
mkdir -p "$state_dir"

repo_digest() {
  docker inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$1" 2>/dev/null || true
}

# A container has no RepoDigests; resolve its image ID first.
container_ref() {
  local image
  image="$(docker inspect --format '{{.Image}}' "$1" 2>/dev/null || true)"
  [[ -n "$image" ]] && repo_digest "$image"
}

previous_server="$(container_ref "velomine-$env-server-1")"
previous_web="$(container_ref "velomine-$env-web-1")"

if ! app_compose "$env" pull --quiet; then
  # Before the first release reaches this environment the tags do not exist yet.
  [[ -z "$previous_server" ]] && { log "[$env] no images to run yet"; exit 0; }
  die "[$env] could not pull the images"
fi
pulled_server="$(repo_digest "$(env_value "$env" VELOMINE_SERVER_IMAGE)")"
pulled_web="$(repo_digest "$(env_value "$env" VELOMINE_WEB_IMAGE)")"
pair="${pulled_server} ${pulled_web}"

if [[ -f "$state_dir/quarantined" && "$(cat "$state_dir/quarantined")" == "$pair" ]]; then
  exit 0 # failed its health check before; waiting for a new pair
fi

if [[ "$previous_server" == "$pulled_server" && "$previous_web" == "$pulled_web" ]]; then
  exit 0 # already running it
fi

log "[$env] running: server ${previous_server:-none}, web ${previous_web:-none}"
log "[$env] new:     server ${pulled_server}, web ${pulled_web}"
app_compose "$env" up --detach --remove-orphans

if wait_healthy "$env"; then
  log "[$env] healthy"
  rm -f "$state_dir/quarantined"
  exit 0
fi

log "[$env] health check failed for the new pair"
printf '%s\n' "$pair" > "$state_dir/quarantined"

[[ -n "$previous_server" && -n "$previous_web" ]] || die "[$env] no previous pair to roll back to"

# Migrations are backward-compatible for one release (AGENTS.md), so the previous server runs on the migrated schema.
log "[$env] rolling back to the previous pair"
VELOMINE_SERVER_IMAGE="$previous_server" VELOMINE_WEB_IMAGE="$previous_web" \
  app_compose "$env" up --detach --remove-orphans

if wait_healthy "$env"; then
  log "[$env] rolled back and healthy"
  exit 0
fi

die "[$env] the rollback is not healthy either; the host needs attention"
