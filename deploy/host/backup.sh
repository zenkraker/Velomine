#!/usr/bin/env bash
# Nightly backup of every environment in BACKUP_ENVS (set in /etc/velomine/restic.env): a pg_dump of its database, its
# ride files and its Data Protection key ring (and the demo baseline), as one restic snapshot tagged with the
# environment. One environment failing does not stop the others; the run still fails at the end.
#
# Retention: prod keeps more history than the others. docs/architecture.md promises deleted data leaves the backups
# within 90 days: the oldest snapshot here is 8 weeks (56 days), and the bucket keeps replaced objects 30 more days.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$(dirname "$0")/lib.sh"

[[ "${EUID}" -eq 0 ]] || die "Run backup.sh as root (or with sudo)."

exec 9>/run/velomine-backup.lock
flock -n 9 || { log "A backup is already running."; exit 0; }

set -a
# shellcheck disable=SC1091
. /etc/velomine/restic.env
set +a
: "${BACKUP_ENVS:?set BACKUP_ENVS in /etc/velomine/restic.env, for example BACKUP_ENVS=\"staging prod\"}"

# First run on a fresh bucket: create the repository once.
restic snapshots >/dev/null 2>&1 || restic init

failed=()
for env in $BACKUP_ENVS; do
  if ! [[ -f "$VELOMINE_DIR/$env/.env" && -f "/etc/velomine/$env/db.env" ]]; then
    log "[$env] not installed on this host; skipped"
    failed+=("$env")
    continue
  fi

  dump_dir="/srv/velomine/backups/$env"
  mkdir -p "$dump_dir"
  paths=("$dump_dir" "/srv/velomine/$env/files" "/srv/velomine/$env/keys")
  [[ "$env" == demo && -d /srv/velomine/baseline ]] && paths+=(/srv/velomine/baseline)

  log "[$env] dumping the database"
  if ! pg "$env" "$PG_IMAGE" pg_dump -Fc -f - > "$dump_dir/velomine.dump.partial"; then
    log "[$env] pg_dump failed"
    rm -f "$dump_dir/velomine.dump.partial"
    failed+=("$env")
    continue
  fi
  mv "$dump_dir/velomine.dump.partial" "$dump_dir/velomine.dump"

  log "[$env] sending the dump, files and keys to restic"
  if ! restic backup "${paths[@]}" --tag "$env"; then
    failed+=("$env")
    continue
  fi

  if [[ "$env" == prod ]]; then
    keep=(--keep-daily 14 --keep-weekly 8)
  else
    keep=(--keep-daily 7 --keep-weekly 4)
  fi
  restic forget --tag "$env" --group-by host,tags "${keep[@]}" || failed+=("$env")
done

restic prune

if ((${#failed[@]})); then
  die "Backup failed for: ${failed[*]}"
fi
log "Backup finished: ${BACKUP_ENVS}"
