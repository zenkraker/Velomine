#!/usr/bin/env bash
# Proves an environment's latest backup can be restored: restores the snapshot to a scratch directory, loads the dump
# into a throwaway PostgreSQL container on this host, and checks the files and key ring are in the snapshot. It never
# touches the managed database or the live files.
#
#   sudo /opt/velomine/restore-check.sh <env>
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

[[ "${EUID}" -eq 0 ]] || die "Run restore-check.sh as root (or with sudo)."
env="${1:-}"
require_env "$env"

set -a
# shellcheck disable=SC1091
. /etc/velomine/restic.env
set +a

scratch="$(mktemp -d /tmp/velomine-restore-XXXXXX)"
db="velomine-restore-check-$env"
cleanup() {
  docker rm -f "$db" >/dev/null 2>&1 || true
  rm -rf "$scratch"
}
trap cleanup EXIT

log "[$env] latest snapshot:"
restic snapshots --tag "$env" --host "$(hostname)" --latest 1

restic restore latest --tag "$env" --host "$(hostname)" --target "$scratch" \
  --include "/srv/velomine/backups/$env"
dump="$scratch/srv/velomine/backups/$env/velomine.dump"
[[ -s "$dump" ]] || die "[$env] the snapshot has no database dump"

for path in "/srv/velomine/$env/files" "/srv/velomine/$env/keys"; do
  restic ls latest --tag "$env" --host "$(hostname)" "$path" | grep -q . || die "[$env] the snapshot has no $path"
done

log "[$env] loading the dump into a scratch PostgreSQL"
docker run -d --name "$db" -e POSTGRES_PASSWORD=restore-check -e POSTGRES_DB=velomine "$PG_IMAGE" >/dev/null
for _ in $(seq 1 30); do
  docker exec "$db" pg_isready -U postgres -d velomine >/dev/null 2>&1 && break
  sleep 1
done
docker cp "$dump" "$db:/tmp/velomine.dump"
docker exec "$db" pg_restore --no-owner --no-privileges -U postgres -d velomine /tmp/velomine.dump

tables="$(docker exec "$db" psql -U postgres -d velomine -tAc \
  "select count(*) from information_schema.tables where table_schema not in ('pg_catalog', 'information_schema')")"
accounts="$(docker exec "$db" psql -U postgres -d velomine -tAc 'select count(*) from accounts.users' 2>/dev/null || echo '?')"
log "[$env] restored ${tables} tables, ${accounts} accounts. Live data was not touched."
(( tables > 0 )) || die "[$env] the restored database is empty"
