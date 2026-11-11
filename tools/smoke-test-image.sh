#!/usr/bin/env bash
# Starts a built image against an empty PostgreSQL the way a host runs it (read-only root, no capabilities) and checks
# that it migrates, answers /health, serves the site and the web app, and reports the expected build.
#
#   tools/smoke-test-image.sh <image> [expected text in /api/v1/server "version"]
#
# Release CI runs it before anything is pushed. It needs only Docker.
set -euo pipefail

image="${1:?usage: tools/smoke-test-image.sh <image> [expected version text]}"
expect="${2:-}"
name="velomine-smoke-$$"

cleanup() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    echo "--- app log ---" >&2
    docker logs "$name-app" 2>&1 | tail -n 100 >&2 || true
  fi
  docker rm -f "$name-app" "$name-db" >/dev/null 2>&1 || true
  docker network rm "$name" >/dev/null 2>&1 || true
  exit $status
}
trap cleanup EXIT

docker network create "$name" >/dev/null

# Same image and version as docker-compose.yml (AGENTS.md: tests run like development).
docker run -d --name "$name-db" --network "$name" \
  -e POSTGRES_DB=velomine -e POSTGRES_USER=velomine -e POSTGRES_PASSWORD=smoke \
  postgres:17 >/dev/null

for _ in $(seq 1 30); do
  docker exec "$name-db" pg_isready -U velomine -d velomine >/dev/null 2>&1 && break
  sleep 1
done

user="$(docker image inspect --format '{{.Config.User}}' "$image")"
[[ -n "$user" && "$user" != "root" && "$user" != "0" ]] || { echo "The image runs as root." >&2; exit 1; }

# Anonymous volumes take the image's ownership of /data/*, like the host's bind mounts owned by the app user.
docker run -d --name "$name-app" --network "$name" -p 127.0.0.1::8080 \
  --read-only --tmpfs /tmp:size=256m,mode=1777 --cap-drop ALL --security-opt no-new-privileges:true \
  -v /data/files -v /data/keys \
  -e CONNECTIONSTRINGS__VELOMINE="Host=$name-db;Database=velomine;Username=velomine;Password=smoke" \
  -e VELOMINE__PUBLICURL=http://localhost:8080 \
  -e VELOMINE__ADMIN__EMAIL=admin@velomine.local \
  -e VELOMINE__ADMIN__PASSWORD=Velomine-smoke-1 \
  "$image" >/dev/null

port="$(docker port "$name-app" 8080/tcp | head -n 1 | sed 's/.*://')"
base="http://127.0.0.1:${port}"

healthy=false
for _ in $(seq 1 60); do
  if curl -fsS --max-time 3 "$base/health" >/dev/null 2>&1; then healthy=true; break; fi
  sleep 2
done
$healthy || { echo "No healthy answer on /health within two minutes." >&2; exit 1; }
echo "ok   /health"

version="$(curl -fsS "$base/api/v1/server" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
[[ -n "$version" ]] || { echo "/api/v1/server has no version." >&2; exit 1; }
if [[ -n "$expect" && "$version" != *"$expect"* ]]; then
  echo "/api/v1/server reports version '$version', expected it to contain '$expect'." >&2
  exit 1
fi
echo "ok   /api/v1/server version $version"

curl -fsS -o /dev/null "$base/" && echo "ok   / (presentation site)"
curl -fsS "$base/app-smoke-route" | grep -q '<base' && echo "ok   web app fallback (index.html)"
