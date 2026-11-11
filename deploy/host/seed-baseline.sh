#!/usr/bin/env bash
# Takes the demo baseline that reset-demo.sh restores. Run it after creating the demo club, coach, riders and sample
# rides. Demo only.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

[[ "${EUID}" -eq 0 ]] || die "Run seed-baseline.sh as root (or with sudo)."
require_env demo

baseline=/srv/velomine/baseline
mkdir -p "$baseline"

log "Dumping the demo database..."
pg demo "$PG_IMAGE" pg_dump -Fc -f - > "$baseline/velomine.dump"

log "Archiving the demo ride files..."
tar --numeric-owner -C /srv/velomine/demo/files -czf "$baseline/files.tar.gz" .

log "Baseline written to $baseline. Reset later with: sudo DEMO_RESET=yes $VELOMINE_DIR/reset-demo.sh"
