#!/usr/bin/env bash
# Installs or updates a host's configuration: Caddy, one compose project per environment, their settings and secrets,
# the update timers and the backup timer. Releases do not need it: the Release and Deploy workflows move the image and
# the host's timers pull it. Run it for the first install and whenever compose, Caddy, a timer or a setting changes.
#
#   DEPLOY_HOST=<ip> ENVS="dev staging prod" deploy/host/deploy.sh
#   DEPLOY_HOST=<ip> ENVS="demo" APEX_ENV=demo deploy/host/deploy.sh
#
# Reads, for each environment, deploy/host/envs/<env>/app.env and db.env, and deploy/host/restic.env (all git-ignored;
# copy the *.example files). The host name of each environment comes from Velomine__PublicUrl in its app.env.
#
#   APEX_ENV      the environment that also answers velomine.eu and www.velomine.eu (only on the host that runs it)
#   BACKUP_ENVS   environments to back up; default: ENVS without dev
#   DEPLOY_USER   default deploy;  SSH_KEY  optional identity file;  ACME_EMAIL  default ops@velomine.eu
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${DEPLOY_HOST:?Set DEPLOY_HOST to the host IP or name}"
: "${ENVS:?Set ENVS to the environments this host runs, for example ENVS=\"dev staging prod\"}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
ACME_EMAIL="${ACME_EMAIL:-ops@velomine.eu}"
APEX_ENV="${APEX_ENV:-}"
APEX_DOMAIN="${APEX_DOMAIN:-velomine.eu}"
IMAGE="${IMAGE:-ghcr.io/zenkraker/velomine}"
BACKUP_ENVS="${BACKUP_ENVS:-$(tr ' ' '\n' <<<"$ENVS" | grep -vx dev | xargs)}"

die() { echo "$*" >&2; exit 1; }

public_host() {
  sed -n 's|^[Vv][Ee][Ll][Oo][Mm][Ii][Nn][Ee]__[Pp][Uu][Bb][Ll][Ii][Cc][Uu][Rr][Ll]=https://\([^/]*\).*|\1|p' "$1" | tail -n 1
}

# Everything is checked before the host is touched.
declare -A hosts
for env in $ENVS; do
  [[ " demo dev staging prod " == *" $env "* ]] || die "Unknown environment '$env'. One of: demo dev staging prod."
  for file in app.env db.env; do
    [[ -f "$here/envs/$env/$file" ]] || die "Missing $here/envs/$env/$file. Copy envs/$file.example and fill it."
  done
  hosts[$env]="$(public_host "$here/envs/$env/app.env")"
  [[ -n "${hosts[$env]}" ]] || die "Velomine__PublicUrl in envs/$env/app.env must be an https:// address."
done
[[ -z "$APEX_ENV" || " $ENVS " == *" $APEX_ENV "* ]] || die "APEX_ENV=$APEX_ENV is not one of ENVS."
[[ -f "$here/restic.env" ]] || echo "Warning: $here/restic.env is missing; the backup timer will fail until it is installed." >&2

# One Caddy site per environment. dev and staging are kept out of search engines.
sites="$(mktemp -d)"
trap 'rm -rf "$sites"' EXIT
for env in $ENVS; do
  addresses="${hosts[$env]}"
  [[ "$env" == "$APEX_ENV" ]] && addresses+=", ${APEX_DOMAIN}, www.${APEX_DOMAIN}"
  {
    echo "${addresses} {"
    echo "	import common"
    [[ "$env" == dev || "$env" == staging ]] && echo '	header X-Robots-Tag "noindex, nofollow"'
    echo "	reverse_proxy velomine-${env}:8080"
    echo "}"
  } > "$sites/$env.caddy"
done

# One TCP connection for the whole run: repeated SSH handshakes to the same host trip per-source connection limits on
# some networks.
ssh_opts=(-o StrictHostKeyChecking=accept-new
  -o ControlMaster=auto -o ControlPath="$HOME/.ssh/velomine-%r@%h:%p" -o ControlPersist=120)
[[ -n "${SSH_KEY:-}" ]] && ssh_opts+=(-i "$SSH_KEY")
remote="${DEPLOY_USER}@${DEPLOY_HOST}"
run() { ssh "${ssh_opts[@]}" "$remote" "$@"; }

echo "Preparing ${remote} for: ${ENVS}"
run "set -e
  sudo install -d -m 755 -o ${DEPLOY_USER} -g ${DEPLOY_USER} /opt/velomine /opt/velomine/sites
  sudo install -d -m 750 -o root -g ${DEPLOY_USER} /etc/velomine
  sudo install -d -m 750 /srv/velomine
  for env in ${ENVS}; do
    sudo install -d -m 755 -o ${DEPLOY_USER} -g ${DEPLOY_USER} /opt/velomine/\$env
    sudo install -d -m 750 -o root -g ${DEPLOY_USER} /etc/velomine/\$env
    sudo install -d -m 750 -o 1654 -g 1654 /srv/velomine/\$env/files /srv/velomine/\$env/keys
  done"

rsync -az --chmod=F644 -e "ssh ${ssh_opts[*]}" \
  "$here/compose.edge.yml" "$here/compose.app.yml" "$here/Caddyfile" \
  "$here/velomine-update@.service" "$here/velomine-update@.timer" \
  "$here/velomine-backup.service" "$here/velomine-backup.timer" \
  "${remote}:/opt/velomine/"
rsync -az --chmod=F755 -e "ssh ${ssh_opts[*]}" \
  "$here/lib.sh" "$here/update.sh" "$here/backup.sh" "$here/restore-check.sh" \
  "$here/seed-baseline.sh" "$here/reset-demo.sh" \
  "${remote}:/opt/velomine/"
rsync -az --delete --chmod=F644 -e "ssh ${ssh_opts[*]}" "$sites/" "${remote}:/opt/velomine/sites/"

echo "Installing settings and secrets..."
for env in $ENVS; do
  run "cat > /opt/velomine/$env/.env" <<EOF
VELOMINE_ENV=${env}
VELOMINE_IMAGE=${IMAGE}:${env}
VELOMINE_HOST=${hosts[$env]}
EOF
  # Read by the app container (root reads it for Docker) and by the scripts; never by other users.
  run "sudo install -m 640 -o root -g ${DEPLOY_USER} /dev/stdin /etc/velomine/$env/app.env" < "$here/envs/$env/app.env"
  run "sudo install -m 600 -o root -g root /dev/stdin /etc/velomine/$env/db.env" < "$here/envs/$env/db.env"
done
if [[ -f "$here/restic.env" ]]; then
  { cat "$here/restic.env"; echo; echo "BACKUP_ENVS=\"${BACKUP_ENVS}\""; } |
    run "sudo install -m 600 -o root -g root /dev/stdin /etc/velomine/restic.env"
fi
run "printf 'ACME_EMAIL=%s\n' '${ACME_EMAIL}' > /opt/velomine/.env"

echo "Starting Caddy and the environments..."
run "set -e
  cd /opt/velomine
  docker compose -f compose.edge.yml up -d --remove-orphans
  # Caddy runs with its admin API off, so it cannot reload: restart it to read the sites.
  docker compose -f compose.edge.yml restart caddy
  for env in ${ENVS}; do
    if docker compose -p velomine-\$env -f compose.app.yml --env-file \$env/.env pull --quiet app; then
      docker compose -p velomine-\$env -f compose.app.yml --env-file \$env/.env up -d --remove-orphans
    else
      echo \"\$env: no image ${IMAGE}:\$env yet; it starts on its first deploy.\"
    fi
  done"

echo "Installing the timers..."
timers=""
for env in $ENVS; do timers+=" velomine-update@${env}.timer"; done
run "set -e
  sudo install -m 644 /opt/velomine/velomine-update@.service /opt/velomine/velomine-update@.timer \
    /opt/velomine/velomine-backup.service /opt/velomine/velomine-backup.timer /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now velomine-backup.timer${timers}"

echo "Waiting for the environments that have an image..."
status=0
for env in $ENVS; do
  url="https://${hosts[$env]}/health"
  if ! run "docker inspect velomine-${env}-app-1 >/dev/null 2>&1"; then
    echo "  ${env}: not running yet (no image)"
    continue
  fi
  ok=false
  for _ in $(seq 1 36); do
    if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then ok=true; break; fi
    sleep 5
  done
  if $ok; then echo "  ${env}: ok  ${url}"; else echo "  ${env}: NOT healthy  ${url}" >&2; status=1; fi
done
[[ $status -eq 0 ]] || echo "Inspect: ssh ${remote} 'docker compose -p velomine-<env> logs --tail=100'" >&2
exit $status
