#!/usr/bin/env bash
set -euo pipefail

# Run as root from the systemd timer, or with sudo.
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run backup.sh as root (or with sudo)." >&2
  exit 1
fi

exec 9>/run/velomine-backup.lock
flock -n 9 || { echo "A backup is already running."; exit 0; }

set -a
# shellcheck disable=SC1091
. /etc/velomine/backup.env
set +a

backup_dir=/srv/velomine/backups
mkdir -p "$backup_dir" /srv/velomine/baseline

echo "Dumping ${PGDATABASE} from ${PGHOST}..."
docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  pg_dump -Fc -f - > "$backup_dir/velomine.dump"

# First run on a fresh bucket: create the repository once.
restic snapshots >/dev/null 2>&1 || restic init

echo "Backing up database dump, files and Data Protection keys..."
restic backup \
  /srv/velomine/backups \
  /srv/velomine/files \
  /srv/velomine/keys \
  /srv/velomine/baseline \
  --tag demo

restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

echo "Backup finished."
