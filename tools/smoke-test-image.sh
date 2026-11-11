#!/usr/bin/env bash
# Starts the server and web images against an empty PostgreSQL the way a host runs them (read-only root, no
# capabilities, the server reachable only through the web image) and checks, through the web image's port, that the
# server migrates and answers, reports the expected build, and that every path reaches the right place: the API, the
# presentation site, the web app and its fallback.
#
#   tools/smoke-test-image.sh <server-image> <web-image> [expected text in /api/v1/server "version"]
#
# Release CI runs it before anything is pushed. It needs only Docker and curl.
set -euo pipefail

server_image="${1:?usage: tools/smoke-test-image.sh <server-image> <web-image> [expected version text]}"
web_image="${2:?usage: tools/smoke-test-image.sh <server-image> <web-image> [expected version text]}"
expect="${3:-}"
name="velomine-smoke-$$"

cleanup() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    echo "--- server log ---" >&2
    docker logs "$name-server" 2>&1 | tail -n 60 >&2 || true
    echo "--- web log ---" >&2
    docker logs "$name-web" 2>&1 | tail -n 20 >&2 || true
  fi
  docker rm -f "$name-web" "$name-server" "$name-db" >/dev/null 2>&1 || true
  docker network rm "$name" >/dev/null 2>&1 || true
  exit $status
}
trap cleanup EXIT

fail() { echo "FAIL $*" >&2; exit 1; }
ok() { echo "ok   $*"; }

for image in "$server_image" "$web_image"; do
  user="$(docker image inspect --format '{{.Config.User}}' "$image")"
  [[ -n "$user" && "$user" != "root" && "$user" != "0" ]] || fail "$image runs as root"
done
ok "both images run as an unprivileged user"

docker network create "$name" >/dev/null

# Same image and version as docker-compose.yml (AGENTS.md: tests run like development).
docker run -d --name "$name-db" --network "$name" \
  -e POSTGRES_DB=velomine -e POSTGRES_USER=velomine -e POSTGRES_PASSWORD=smoke \
  postgres:17 >/dev/null
for _ in $(seq 1 30); do
  docker exec "$name-db" pg_isready -U velomine -d velomine >/dev/null 2>&1 && break
  sleep 1
done

# shellcheck disable=SC2054 # the commas belong to the --tmpfs value
hardened=(--read-only --tmpfs /tmp:size=64m,mode=1777 --cap-drop ALL --security-opt no-new-privileges:true)

# The server is not published: like on a host, only the web image reaches it, by the name `server`.
# Anonymous volumes take the image's ownership of /data/*, like the hosts' bind mounts owned by the app user.
docker run -d --name "$name-server" --network "$name" --network-alias server "${hardened[@]}" \
  -v /data/files -v /data/keys \
  -e CONNECTIONSTRINGS__VELOMINE="Host=$name-db;Database=velomine;Username=velomine;Password=smoke" \
  -e VELOMINE__PUBLICURL=http://localhost:8080 \
  -e VELOMINE__ADMIN__EMAIL=admin@velomine.local \
  -e VELOMINE__ADMIN__PASSWORD=Velomine-smoke-1 \
  "$server_image" >/dev/null

docker run -d --name "$name-web" --network "$name" -p 127.0.0.1::8080 "${hardened[@]}" "$web_image" >/dev/null

port="$(docker port "$name-web" 8080/tcp | head -n 1 | sed 's/.*://')"
base="http://127.0.0.1:${port}"

healthy=false
for _ in $(seq 1 60); do
  if curl -fsS --max-time 3 "$base/health" >/dev/null 2>&1; then healthy=true; break; fi
  sleep 2
done
$healthy || fail "no healthy answer on /health through the web image within two minutes"
ok "/health through the web image"

version="$(curl -fsS "$base/api/v1/server" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
[[ -n "$version" ]] || fail "/api/v1/server has no version"
[[ -z "$expect" || "$version" == *"$expect"* ]] || fail "/api/v1/server reports '$version', expected '$expect'"
ok "/api/v1/server version $version"

web_version="$(curl -fsS "$base/version.json" | sed -n 's/.*"version":"\([^"]*\)".*"revision":"\([^"]*\)".*/\1+\2/p')"
[[ -n "$web_version" ]] || fail "/version.json has no version"
[[ -z "$expect" || "$web_version" == *"${expect#+}"* ]] || fail "/version.json reports '$web_version', expected '$expect'"
ok "/version.json (web image) $web_version"

# status <path>: the HTTP status, without following redirects.
status() { curl -s -o /dev/null -w '%{http_code}' "$base$1"; }
body() { curl -fsS "$base$1"; }

expect_status() {
  local want="$1" path="$2" got
  got="$(status "$path")"
  [[ "$got" == "$want" ]] || fail "$path answered $got, expected $want"
  ok "$path -> $want"
}

# The presentation site, served before the app.
body / | grep -q '<title>Velomine' || fail "/ is not the presentation site"
ok "/ -> presentation site"
for page in status pricing demo contact principles privacy terms security; do
  body "/$page/" | grep -q 'class="wordmark"' || fail "/$page/ is not a site page"
  location="$(curl -s -o /dev/null -w '%{redirect_url}' "$base/$page")"
  [[ "$(status "/$page")" == 301 && "$location" == *"/$page/" ]] || fail "/$page does not redirect to /$page/"
done
ok "site pages, and their trailing-slash redirects"
expect_status 200 /static/site.css
expect_status 200 /.well-known/security.txt
expect_status 200 /robots.txt

# The web app: its files, and any path without an extension falls back to its index.html.
expect_status 200 /main.dart.js
for route in /sign-in /rides/0190a5b2-7c3e-7000-8000-000000000000 /settings/profile /it; do
  body "$route" | grep -q 'flutter_bootstrap.js' || fail "$route is not the web app"
done
ok "app routes -> web app"

# Missing files and API paths are 404, never the app.
expect_status 404 /assets/missing.png
expect_status 404 /api/v1/does-not-exist
expect_status 404 /api
