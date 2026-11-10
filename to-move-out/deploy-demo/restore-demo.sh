#!/usr/bin/env bash
set -euo pipefail

# Restores the latest restic snapshot into a scratch database and directory.
# It never touches the live database or the live files.
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run restore-demo.sh as root (or with sudo)." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. /etc/velomine/backup.env
set +a

restore_dir=/tmp/velomine-restore
rm -rf "$restore_dir"
mkdir -p "$restore_dir"

echo "Restoring latest snapshot to ${restore_dir}..."
restic restore latest --target "$restore_dir"

echo "Restoring into scratch database velomine_restore..."
docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  dropdb --if-exists velomine_restore

docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  createdb velomine_restore

docker run --rm --network host --env-file /etc/velomine/backup.env \
  -v "${restore_dir}:/restore:ro" \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  pg_restore --no-owner --no-privileges -d velomine_restore \
  /restore/srv/velomine/backups/velomine.dump

docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  psql -d velomine_restore -c \
  "select count(*) as tables from information_schema.tables where table_schema not in ('pg_catalog', 'information_schema');"

echo "Restore verification finished. Live data was not touched."
