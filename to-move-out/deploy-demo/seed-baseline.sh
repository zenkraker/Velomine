#!/usr/bin/env bash
set -euo pipefail

# Creates the demo baseline used by reset-demo.sh. Run with sudo after you have
# created the demo club, coach, riders and sample rides.
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run seed-baseline.sh as root (or with sudo)." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. /etc/velomine/backup.env
set +a

mkdir -p /srv/velomine/baseline

echo "Dumping ${PGDATABASE}..."
docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  pg_dump -Fc -f - > /srv/velomine/baseline/velomine.dump

echo "Archiving ride files..."
tar --numeric-owner -C /srv/velomine/files -czf /srv/velomine/baseline/files.tar.gz .

echo "Baseline written to /srv/velomine/baseline."
echo "Reset later with: sudo DEMO_RESET=yes /opt/velomine/reset-demo.sh"
