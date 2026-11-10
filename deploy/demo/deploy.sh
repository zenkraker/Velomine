#!/usr/bin/env bash
set -euo pipefail

# Deploys the demo stack to one VPS. Run from the repository root:
#   DEPLOY_HOST=... VELOMINE_IMAGE=... ./deploy/demo/deploy.sh

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
demo_dir="${repo_root}/deploy/demo"

: "${DEPLOY_HOST:?Set DEPLOY_HOST to the VPS IP or hostname}"
: "${VELOMINE_IMAGE:?Set VELOMINE_IMAGE to the image tag or digest}"
: "${VELOMINE_ENV_FILE:=${demo_dir}/velomine.env}"

DEPLOY_USER="${DEPLOY_USER:-deploy}"
REMOTE_DIR="${REMOTE_DIR:-/opt/velomine}"
VELOMINE_DEMO_HOST="${VELOMINE_DEMO_HOST:-demo.velomine.eu}"
VELOMINE_ROOT_HOST="${VELOMINE_ROOT_HOST:-velomine.eu}"
VELOMINE_WWW_HOST="${VELOMINE_WWW_HOST:-www.velomine.eu}"
ACME_EMAIL="${ACME_EMAIL:-ops@velomine.eu}"
REGISTRY_HOST="${REGISTRY_HOST:-rg.nl-ams.scw.cloud}"

[[ -f "$VELOMINE_ENV_FILE" ]] || {
  echo "Missing $VELOMINE_ENV_FILE. Copy velomine.env.example and fill it." >&2
  exit 1
}

# One TCP connection for the whole deploy: repeated SSH handshakes to the same
# host trip per-source connection limits on some networks.
ssh_opts=(-o StrictHostKeyChecking=accept-new
  -o ControlMaster=auto -o ControlPath="$HOME/.ssh/velomine-%r@%h:%p" -o ControlPersist=120)
[[ -n "${SSH_KEY:-}" ]] && ssh_opts+=(-i "$SSH_KEY")
remote="${DEPLOY_USER}@${DEPLOY_HOST}"

echo "Preparing ${remote}:${REMOTE_DIR}..."
ssh "${ssh_opts[@]}" "$remote" \
  "sudo install -d -m 700 /etc/velomine; sudo install -d -m 755 -o ${DEPLOY_USER} -g ${DEPLOY_USER} ${REMOTE_DIR}"

rsync -az -e "ssh ${ssh_opts[*]}" \
  "${demo_dir}/docker-compose.yml" \
  "${demo_dir}/Caddyfile" \
  "${demo_dir}/backup.sh" \
  "${demo_dir}/restore-demo.sh" \
  "${demo_dir}/reset-demo.sh" \
  "${demo_dir}/seed-baseline.sh" \
  "${demo_dir}/update-demo.sh" \
  "${demo_dir}/velomine-backup.service" \
  "${demo_dir}/velomine-backup.timer" \
  "${demo_dir}/velomine-update.service" \
  "${demo_dir}/velomine-update.timer" \
  "${remote}:${REMOTE_DIR}/"

ssh "${ssh_opts[@]}" "$remote" "cat > ${REMOTE_DIR}/.env" <<EOF
VELOMINE_IMAGE=${VELOMINE_IMAGE}
VELOMINE_DEMO_HOST=${VELOMINE_DEMO_HOST}
VELOMINE_ROOT_HOST=${VELOMINE_ROOT_HOST}
VELOMINE_WWW_HOST=${VELOMINE_WWW_HOST}
ACME_EMAIL=${ACME_EMAIL}
EOF

if [[ -n "${REGISTRY_USER:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  echo "Logging in to ${REGISTRY_HOST}..."
  printf '%s' "$REGISTRY_PASSWORD" | ssh "${ssh_opts[@]}" "$remote" \
    "docker login ${REGISTRY_HOST} -u '${REGISTRY_USER}' --password-stdin"
fi

echo "Installing the application environment..."
ssh "${ssh_opts[@]}" "$remote" \
  "sudo tee /etc/velomine/velomine.env >/dev/null && sudo chown root:${DEPLOY_USER} /etc/velomine/velomine.env && sudo chmod 640 /etc/velomine/velomine.env" \
  < "$VELOMINE_ENV_FILE"

if [[ -f "${demo_dir}/backup.env" ]]; then
  echo "Installing the backup environment..."
  ssh "${ssh_opts[@]}" "$remote" \
    "sudo tee /etc/velomine/backup.env >/dev/null && sudo chmod 600 /etc/velomine/backup.env" \
    < "${demo_dir}/backup.env"
else
  echo "Warning: deploy/demo/backup.env is missing; the backup timer will fail until it is installed." >&2
fi

echo "Pulling and starting the stack..."
ssh "${ssh_opts[@]}" "$remote" \
  "cd ${REMOTE_DIR} && chmod +x backup.sh restore-demo.sh reset-demo.sh seed-baseline.sh update-demo.sh && docker compose pull && docker compose up -d --remove-orphans"

echo "Installing the backup timer..."
ssh "${ssh_opts[@]}" "$remote" \
  "sudo install -m 644 ${REMOTE_DIR}/velomine-backup.service /etc/systemd/system/velomine-backup.service && sudo install -m 644 ${REMOTE_DIR}/velomine-backup.timer /etc/systemd/system/velomine-backup.timer && sudo systemctl daemon-reload && sudo systemctl enable --now velomine-backup.timer"

echo "Installing the image update timer..."
ssh "${ssh_opts[@]}" "$remote" \
  "sudo install -m 644 ${REMOTE_DIR}/velomine-update.service /etc/systemd/system/velomine-update.service && sudo install -m 644 ${REMOTE_DIR}/velomine-update.timer /etc/systemd/system/velomine-update.timer && sudo systemctl daemon-reload && sudo systemctl enable --now velomine-update.timer"

echo "Waiting for https://${VELOMINE_DEMO_HOST}/health ..."
for _ in $(seq 1 60); do
  if curl -fsS --max-time 5 "https://${VELOMINE_DEMO_HOST}/health" >/dev/null; then
    echo "OK: https://${VELOMINE_DEMO_HOST}"
    exit 0
  fi
  sleep 5
done

echo "Health check failed. Inspect:" >&2
echo "  ssh ${remote} 'cd ${REMOTE_DIR} && docker compose logs --tail=100'" >&2
exit 1
