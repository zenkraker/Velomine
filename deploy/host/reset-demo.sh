#!/usr/bin/env bash
# Restores the demo to its seeded baseline. This destroys the current demo database and ride files, so it is guarded by
# DEMO_RESET=yes, and it refuses any environment but demo. The Data Protection keys are kept.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

[[ "${EUID}" -eq 0 ]] || die "Run reset-demo.sh as root (or with sudo)."
[[ "${DEMO_RESET:-}" == "yes" ]] || die "Refusing to reset. Run with: sudo DEMO_RESET=yes $0"
require_env demo

set -a
# shellcheck disable=SC1091
. /etc/velomine/demo/db.env
set +a
[[ -n "${PGDATABASE:-}" ]] || die "PGDATABASE is not set in /etc/velomine/demo/db.env"

baseline=/srv/velomine/baseline
[[ -f "$baseline/velomine.dump" && -f "$baseline/files.tar.gz" ]] || die "Missing $baseline. Run seed-baseline.sh first."

log "Stopping the demo server..."
app_compose demo stop server

log "Restoring the demo database..."
pg demo "$PG_IMAGE" dropdb --if-exists "$PGDATABASE"
pg demo "$PG_IMAGE" createdb "$PGDATABASE"
pg demo -v "${baseline}:/baseline:ro" "$PG_IMAGE" \
  pg_restore --no-owner --no-privileges -d "$PGDATABASE" /baseline/velomine.dump

log "Restoring the demo ride files..."
find /srv/velomine/demo/files -mindepth 1 -delete
tar --numeric-owner -C /srv/velomine/demo/files -xzf "$baseline/files.tar.gz"

log "Starting the demo server..."
app_compose demo up -d --wait || die "The demo did not become healthy: cd $VELOMINE_DIR/demo && docker compose logs --tail=100"
log "Demo reset."
