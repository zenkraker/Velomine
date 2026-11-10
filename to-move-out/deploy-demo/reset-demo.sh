#!/usr/bin/env bash
set -euo pipefail

# Restores the seeded demo baseline. This destroys the current demo database
# and ride files, so it is guarded by DEMO_RESET=yes.
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run reset-demo.sh as root (or with sudo)." >&2
  exit 1
fi

if [[ "${DEMO_RESET:-}" != "yes" ]]; then
  echo "Refusing to reset. Run with: sudo DEMO_RESET=yes $0" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. /etc/velomine/backup.env
# shellcheck disable=SC1091
. /opt/velomine/.env
set +a

baseline=/srv/velomine/baseline
if [[ ! -f "$baseline/velomine.dump" || ! -f "$baseline/files.tar.gz" ]]; then
  echo "Missing $baseline/velomine.dump or files.tar.gz. Run seed-baseline.sh first." >&2
  exit 1
fi

cd /opt/velomine
echo "Stopping the app..."
docker compose stop app

echo "Restoring the demo database..."
docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  dropdb --if-exists "$PGDATABASE"

docker run --rm --network host --env-file /etc/velomine/backup.env \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  createdb "$PGDATABASE"

docker run --rm --network host --env-file /etc/velomine/backup.env \
  -v "${baseline}:/baseline:ro" \
  postgres:17-alpine@sha256:3540c0362c809df084ffac0ae69fe794515f9de92692f02178bcdce0ef0302ac \
  pg_restore --no-owner --no-privileges -d "$PGDATABASE" /baseline/velomine.dump

echo "Restoring the demo ride files..."
find /srv/velomine/files -mindepth 1 -delete
tar --numeric-owner -C /srv/velomine/files -xzf "$baseline/files.tar.gz"

echo "Starting the app..."
docker compose start app

for _ in $(seq 1 30); do
  if curl -fsS --max-time 5 "https://${VELOMINE_DEMO_HOST}/health" >/dev/null; then
    echo "Demo reset. https://${VELOMINE_DEMO_HOST}"
    exit 0
  fi
  sleep 4
done

echo "App did not become healthy. Check: cd /opt/velomine && docker compose logs --tail=100" >&2
exit 1
