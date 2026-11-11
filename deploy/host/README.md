# Velomine host

How the hosted environments run. A self-hoster needs none of this: `docker-compose.yml` at the repository root is enough.

One VPS runs Traefik and one compose project per environment. **Only the demo runs until there are customers**; dev,
staging and prod are described here and commented out in `infra/`.

| Environment | Address | Running |
|-------------|---------|---------|
| demo | `https://demo.velomine.eu`, and `velomine.eu` and `www` until prod launches | yes |
| dev | `https://dev.velomine.eu` | no |
| staging | `https://staging.velomine.eu` | no |
| prod | `https://app.velomine.eu` | no |

`infra/` creates the VPS, the database instance, DNS and the backup bucket. This folder holds what runs on the VPS.

## How it fits together

```
internet ─► Traefik (traefik/compose.yaml, ports 80/443, Let's Encrypt)
              │  network "proxy": web containers only
              ▼
            velomine-demo (app/compose.yaml)
              web    nginx: the web app and the site; /api, /health, /openapi, /signin-oidc ─► server
              server .NET API, on the network velomine-demo only ─► managed PostgreSQL (private network)
```

On the VPS, each folder here has a twin:

| Repository | Host | Holds |
|------------|------|-------|
| `traefik/compose.yaml` | `/opt/velomine/traefik/compose.yaml` | Traefik |
| `app/compose.yaml` | `/opt/velomine/<env>/compose.yaml` | one environment, the same file for each |
| `app/.env.example` | `/opt/velomine/<env>/.env` | the environment, its **version** and its host names |
| `envs/<env>/app.env` (git-ignored) | `/opt/velomine/<env>/app.env` | the server's settings and secrets |
| `envs/<env>/db.env` (git-ignored) | `/etc/velomine/<env>/db.env` | the database login for backups, root only |
| `restic.env` (git-ignored) | `/etc/velomine/restic.env` | the backup repository, root only |
| `*.sh`, `velomine-backup.*` | `/opt/velomine/`, `/etc/systemd/system/` | backups and the demo reset |

- **Two images, one version.** `ghcr.io/zenkraker/velomine-server` (the API) and `ghcr.io/zenkraker/velomine-web` (nginx
  with the web app and the presentation site) are built together and always run at the same version.
- **Traefik** gets and renews the certificates and routes each host name to that environment's web container. It reads
  the routes from the labels in `app/compose.yaml` through the Docker socket, mounted read-only. Revisit that (the file
  provider or a socket proxy) before prod holds a club's real data.
- **Isolation.** Each environment is its own compose project (`velomine-<env>`) with its own network, settings and
  secrets, data (`/srv/velomine/<env>/`) and database user. Only web containers join `proxy`, so nothing on it can
  reach another environment's server.

## Releasing

CI builds, tests and pushes the images; deploying is done by hand. GitHub has no key to the VPS.

```
pull request ──► CI (.github/workflows/ci.yml)
merge to main ──► Release: CI ─► build both ─► smoke test ─► push :0.0.0-main.<run>, :sha-<commit>
tag vX.Y.Z    ──► Release: CI ─► build both ─► smoke test ─► push :X.Y.Z, :X.Y, :sha-<commit>
```

1. Tag the release and wait for the *Release* workflow to go green:

   ```bash
   git tag v1.2.0 && git push origin v1.2.0
   ```

2. On the VPS, set the version and start it:

   ```bash
   ssh deploy@<ip>
   cd /opt/velomine/demo
   sed -i 's/^VELOMINE_VERSION=.*/VELOMINE_VERSION=1.2.0/' .env
   docker compose pull
   docker compose up -d --wait
   ```

   `--wait` returns once the web container is healthy. Its health check goes through nginx to the server, so healthy
   means both answer. If it fails, it says so; look at `docker compose logs --tail=100`.

3. **Roll back** the same way, with the previous version. Migrations are backward-compatible for one release, so the
   previous server runs on the migrated schema.

`https://demo.velomine.eu/api/v1/server` reports the server's version and commit, and `/version.json` reports the web
image's.

## One-time setup

### GitHub

- **The images** need nothing: pushed from this public repository, `velomine-server` and `velomine-web` are public on
  GHCR, so the host pulls them without credentials. The old `velomine` package can be deleted.
- **Branch protection on `main`:** require a pull request and the CI checks. Protect tags `v*` so only maintainers can
  start a release.

### Settings and secrets

On your machine, in this folder (all git-ignored):

```bash
mkdir -p envs/demo
cp envs/app.env.example envs/demo/app.env
cp envs/db.env.example  envs/demo/db.env
cp restic.env.example restic.env
```

Fill them from `tofu output` and your secret store. The demo uses the database `velomine` and the instance's initial
user (`db_user`, with the password you gave OpenTofu), not a `velomine_demo` user.

### Install

From the repository root, with `host=deploy@<ip>` (`tofu -chdir=infra output -raw app_public_ip`):

```bash
cd deploy/host

# Folders: the compose files for the deploy user, secrets for root, data for the containers' user (1654).
ssh "$host" 'set -e
  sudo install -d -m 755 -o deploy -g deploy /opt/velomine /opt/velomine/traefik /opt/velomine/demo
  sudo install -d -m 750 -o root -g root /etc/velomine /etc/velomine/demo
  sudo install -d -m 750 -o 1654 -g 1654 /srv/velomine/demo/files /srv/velomine/demo/keys'

# Traefik, then the demo's compose file and settings. Write .env on the host from app/.env.example.
scp traefik/compose.yaml "$host":/opt/velomine/traefik/
scp app/compose.yaml "$host":/opt/velomine/demo/
scp app/.env.example "$host":/opt/velomine/demo/.env
scp envs/demo/app.env "$host":/opt/velomine/demo/app.env
ssh "$host" 'chmod 600 /opt/velomine/demo/app.env'

# The backup secrets, root only.
ssh "$host" 'sudo install -m 600 /dev/stdin /etc/velomine/demo/db.env' < envs/demo/db.env
ssh "$host" 'sudo install -m 600 /dev/stdin /etc/velomine/restic.env' < restic.env

# Backups and the demo reset.
scp lib.sh backup.sh restore-check.sh seed-baseline.sh reset-demo.sh velomine-backup.service velomine-backup.timer \
  "$host":/opt/velomine/
ssh "$host" 'set -e
  chmod 755 /opt/velomine/*.sh
  sudo install -m 644 /opt/velomine/velomine-backup.service /opt/velomine/velomine-backup.timer /etc/systemd/system/
  sudo systemctl daemon-reload && sudo systemctl enable --now velomine-backup.timer'

# Start.
ssh "$host" 'set -e
  cd /opt/velomine/traefik && docker compose up -d
  cd /opt/velomine/demo && docker compose pull && docker compose up -d --wait'
```

Edit `/opt/velomine/demo/.env` on the host before the last step: `VELOMINE_VERSION` must be a released version.

To change a setting later, copy the file again (`scp envs/demo/app.env ...`) and run `docker compose up -d --wait` in
the environment's folder; compose recreates what changed.

## Moving the demo to this layout

The demo VPS still runs the old single-image layout: Caddy and one app container in `/opt/velomine/docker-compose.yml`,
data in `/srv/velomine/files` and `/srv/velomine/keys`, an update timer, and the image from the Scaleway registry. Once
a release tag has built the new images, stop it and move the data. Keep the Data Protection keys: they sign the
sessions, and without them every member is signed out.

```bash
ssh "$host" 'set -e
  cd /opt/velomine && docker compose down
  sudo systemctl disable --now velomine-update.timer || true
  sudo rm -f /etc/systemd/system/velomine-update.service /etc/systemd/system/velomine-update.timer
  sudo systemctl daemon-reload
  sudo mkdir -p /srv/velomine/demo /srv/velomine/backups/demo
  sudo mv /srv/velomine/files /srv/velomine/keys /srv/velomine/demo/
  sudo mv /srv/velomine/backups/velomine.dump /srv/velomine/backups/demo/ 2>/dev/null || true
  rm -f /opt/velomine/docker-compose.yml /opt/velomine/Caddyfile /opt/velomine/update-demo.sh \
    /opt/velomine/restore-demo.sh /opt/velomine/.env
  sudo rm -f /etc/velomine/velomine.env /etc/velomine/backup.env'
```

Then follow *Install*. The demo is down from `docker compose down` until the new pair answers. Its database stays where
it is. Older restic snapshots of the demo carry the tag `demo` too, so the same retention applies to them.

## Turning on dev, staging or prod

1. `infra/`: resize the VPS, uncomment the environment's database, user and DNS record, `tofu apply`
   (`infra/README.md`).
2. Here: create `envs/<env>/app.env` and `db.env` (database and user `velomine_<env>`), then follow *Install* with
   `<env>` in place of `demo`: its `.env` sets `VELOMINE_ENV`, its host names and, for dev and staging, `noindex`.
3. Add it to `BACKUP_ENVS` in `restic.env` and copy that again (dev is usually left out).
4. When prod launches, move `velomine.eu` and `www` from the demo's `VELOMINE_ROUTER_RULE` to prod's, in both `.env`
   files, and run `docker compose up -d` in both folders.

## Backups

`velomine-backup.timer` runs `backup.sh` nightly at 03:15 UTC. For each environment in `BACKUP_ENVS`
(`/etc/velomine/restic.env`), it sends a `pg_dump -Fc` of the database, the ride files and the Data Protection key ring
to restic in the backup bucket, tagged with the environment (and the demo baseline for the demo). One environment
failing does not stop the others; the run fails at the end. The managed database also keeps its own 7-day backups.

Retention: prod 14 daily and 8 weekly snapshots, the others 7 daily and 4 weekly. With 30 days of bucket versioning,
deleted data leaves the backups within 90 days, as `docs/architecture.md` promises.

```bash
ssh "$host" 'systemctl list-timers velomine-backup.timer; sudo journalctl -u velomine-backup -n 50'
ssh "$host" 'sudo /opt/velomine/restore-check.sh demo'
```

`restore-check.sh <env>` restores the latest snapshot into a throwaway PostgreSQL container on the host and checks
that the dump loads and the files and keys are in it. It never touches the live database or files.

## Day to day

```bash
ssh "$host" 'cd /opt/velomine/demo && docker compose ps && docker compose logs --tail=100'   # the server and nginx
ssh "$host" 'cd /opt/velomine/traefik && docker compose logs --tail=50'                      # Traefik and certificates
```

### The demo

1. Open `https://demo.velomine.eu` and sign in as the admin from `envs/demo/app.env`.
2. Create the demo club, a coach and a few riders; upload `docs/samples/sample-ride.gpx` a few times; create a share
   link and check the coach view.
3. Take the baseline: `ssh "$host" 'sudo /opt/velomine/seed-baseline.sh'`.
4. Reset to it later: `ssh "$host" 'sudo DEMO_RESET=yes /opt/velomine/reset-demo.sh'`.

### Uptime and errors

- An external HTTPS check on `/health` (Better Stack or any monitor).
- Sentry EU: set `Velomine__Telemetry__Sentry__Dsn` and `__Environment` in `envs/<env>/app.env`, copy it again and run
  `docker compose up -d --wait`.
- Alert on disk over 80 %, a backup older than 26 hours and TLS expiry.

## Troubleshooting

- **SSH times out while `http://<ip>/` answers.** Something on your network rate-limits new connections to port 22 for
  that address. Wait a few minutes and connect once.
- **`404` from Traefik.** No router matches the host name: check `VELOMINE_ROUTER_RULE` in `/opt/velomine/<env>/.env`
  and that the web container is running and on the `proxy` network.
- **`502` from nginx.** The server is not answering: `docker compose logs server` in the environment's folder. Usually
  the database: check the private network and the user's privilege on its database.
- **No certificate.** Let's Encrypt must reach port 80 for every host name; check DNS and the Traefik log.
- **`up --wait` fails.** `docker compose ps` shows which container is unhealthy and `docker compose logs` why. Set the
  previous version in `.env` and run it again to roll back.

## Boundary

The demo holds synthetic accounts and sample rides only. Before a club's real member or health data goes on prod, move
prod to its own VPS and an HA database, revisit the Docker socket, and have the DPA, retention and a tested restore in
place.
