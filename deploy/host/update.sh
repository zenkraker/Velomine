#!/usr/bin/env bash
# Runs one environment's image pointer: pulls ghcr.io/zenkraker/velomine:<env>, which the Deploy workflow moves,
# recreates the app and rolls back to the digest that was running before if the new one does not answer /health.
# A digest that failed is quarantined, so the timer does not retry it every minute; a later, different image is still
# deployed. Started by velomine-update@<env>.timer.
#
#   update.sh <env>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

env="${1:-}"
require_env "$env"

state_dir="$VELOMINE_DIR/$env/state"
container="velomine-$env-app-1"
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

previous="$(container_ref "$container")"

if ! app_compose "$env" pull --quiet app; then
  # Before the first release reaches this environment the tag does not exist yet.
  [[ -z "$previous" ]] && { log "[$env] no image to run yet"; exit 0; }
  die "[$env] could not pull $(env_value "$env" VELOMINE_IMAGE)"
fi
pulled="$(repo_digest "$(env_value "$env" VELOMINE_IMAGE)")"

if [[ -f "$state_dir/quarantined" && "$(cat "$state_dir/quarantined")" == "$pulled" ]]; then
  exit 0 # failed its health check before; waiting for a new image
fi

if [[ -n "$previous" && "$previous" == "$pulled" ]]; then
  exit 0 # already running it
fi

log "[$env] running:  ${previous:-none}"
log "[$env] new:      ${pulled:-unknown}"
app_compose "$env" up --detach --remove-orphans app

if wait_healthy "$env"; then
  log "[$env] healthy:  ${pulled}"
  rm -f "$state_dir/quarantined"
  exit 0
fi

log "[$env] health check failed for ${pulled:-the pulled image}"
printf '%s\n' "$pulled" > "$state_dir/quarantined"

[[ -n "$previous" ]] || die "[$env] no previous image to roll back to"

# Migrations are backward-compatible for one release (AGENTS.md), so the previous image runs on the migrated schema.
log "[$env] rolling back to ${previous}"
VELOMINE_IMAGE="$previous" app_compose "$env" up --detach --remove-orphans app

if wait_healthy "$env"; then
  log "[$env] rolled back and healthy: ${previous}"
  exit 0
fi

die "[$env] the rollback is not healthy either; the host needs attention"
