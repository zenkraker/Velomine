# Shared by the scripts that run on a host. Source it; do not run it.
# shellcheck shell=bash

VELOMINE_DIR=/opt/velomine
VELOMINE_ENVS_KNOWN="demo dev staging prod"
# Same pinned client as the managed PostgreSQL 17 server. Used by the scripts that source this file.
# shellcheck disable=SC2034
PG_IMAGE=postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac

log() { printf '%s %s\n' "$(date -Is)" "$*"; }
die() { log "$*" >&2; exit 1; }

# require_env <env>: the environment is one we know and is installed on this host.
require_env() {
  local env="${1:-}"
  [[ " $VELOMINE_ENVS_KNOWN " == *" $env "* ]] || die "Unknown environment '${env}'. One of: ${VELOMINE_ENVS_KNOWN}."
  [[ -f "$VELOMINE_DIR/$env/.env" ]] || die "Environment '${env}' is not installed on this host (no $VELOMINE_DIR/$env/.env)."
}

# app_compose <env> <compose args...>
app_compose() {
  local env="$1"; shift
  docker compose -p "velomine-$env" -f "$VELOMINE_DIR/compose.app.yml" --env-file "$VELOMINE_DIR/$env/.env" "$@"
}

# env_value <env> <KEY>: a value from <env>/.env (VELOMINE_IMAGE, VELOMINE_HOST, ...).
env_value() { sed -n "s/^$2=//p" "$VELOMINE_DIR/$1/.env" | tail -n 1; }

# healthy <env>: /health through Caddy on the loopback, so a broken public path
# or DNS does not look like a broken image.
healthy() {
  local host
  host="$(env_value "$1" VELOMINE_HOST)"
  curl -fsS --max-time 5 --resolve "${host}:443:127.0.0.1" "https://${host}/health" >/dev/null 2>&1
}

# wait_healthy <env> [attempts] [interval]
wait_healthy() {
  local env="$1" attempts="${2:-24}" interval="${3:-5}" i
  for ((i = 1; i <= attempts; i++)); do
    healthy "$env" && return 0
    sleep "$interval"
  done
  return 1
}

# pg <env> <docker run args...>: a PostgreSQL client with the environment's db.env.
pg() {
  local env="$1"; shift
  docker run --rm --network host --env-file "/etc/velomine/$env/db.env" "$@"
}
