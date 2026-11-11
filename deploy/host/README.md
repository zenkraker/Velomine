# Velomine host

How the hosted environments run. A self-hoster needs none of this: `docker-compose.yml` at the repository root is enough.

One VPS runs Traefik and one compose project per environment. **Only the demo runs until there are customers**; dev,
staging and prod are written out and commented out (`environments`, `.github/workflows/release.yml`, `infra/`).

| Environment | Address | Gets a new release | Running |
|-------------|---------|--------------------|---------|
| demo | `https://demo.velomine.eu`, and `velomine.eu` and `www` until prod launches | a tag `vX.Y.Z`, after an approval | yes |
| dev | `https://dev.velomine.eu` | every merge to `main` | no |
| staging | `https://staging.velomine.eu` | a tag `vX.Y.Z` | no |
| prod | `https://app.velomine.eu` | the same images, after an approval | no |

`infra/` creates the VPS, the database instance, DNS and the backup bucket. This folder holds what runs on the VPS.

## How it fits together

```
internet ─► Traefik (compose.traefik.yml, ports 80/443, Let's Encrypt)
              │  network "proxy": web containers only
              ▼
            velomine-demo (compose.app.yml)
              web    nginx: the web app and the site; /api, /health, /openapi, /signin-oidc ─► server
              server .NET API, on the network velomine-demo only ─► managed PostgreSQL (private network)
```

- **Two images, one origin.** `ghcr.io/zenkraker/velomine-server` (the API) and `ghcr.io/zenkraker/velomine-web` (nginx
  with the web app and the presentation site) are built together with one version and always move together.
- **Traefik** gets and renews the certificates and routes each host name to that environment's web container. It reads
  the routes from the labels in `compose.app.yml` through the Docker socket, mounted read-only. Revisit that (the file
  provider or a socket proxy) before prod holds a club's real data.
- **Isolation.** Each environment is its own compose project (`velomine-<env>`) with its own network, settings and
  secrets (`/etc/velomine/<env>/`), data (`/srv/velomine/<env>/`) and database user. Only web containers join `proxy`,
  so nothing on it can reach another environment's server.

## How a release moves

```
pull request ──► CI (.github/workflows/ci.yml)
merge to main ──► Release: CI ─► build both images ─► smoke test together ─► push :sha-<commit>
tag vX.Y.Z    ──► Release: CI ─► build both images ─► smoke test together ─► push :X.Y.Z ─► (approve) demo
```

- **The host pulls.** `velomine-update@<env>.timer` runs `update.sh <env>` every minute. It pulls the environment's two
  tags (`:demo`), recreates the pair and waits up to two minutes for `/health` through Traefik. If the new pair never
  becomes healthy, it **rolls both back to the pair that was running before** and quarantines the bad one. GitHub holds
  no SSH key and no host secret.
- **The workflow checks.** The deploy job waits until `GET /api/v1/server` reports the new commit (`version` ends in
  `+<short sha>`) and `/version.json` (the web image) reports the same commit. A rolled-back pair shows in GitHub as a
  failed deployment.
- **Roll back** by running the *Deploy* workflow by hand with the environment and the previous tag. Migrations are
  backward-compatible for one release, so the previous server runs on the migrated schema.

## One-time setup

### GitHub

1. **Environments** (*Settings → Environments*): `demo` with the variable `PUBLIC_URL` = `https://demo.velomine.eu`,
   a required reviewer, and deployments limited to the branch `main` and tags `v*`. (`dev`, `staging` and `prod` exist
   already with their `PUBLIC_URL`; they are unused until turned on.)
2. **The images** need nothing: pushed from this public repository, `velomine-server` and `velomine-web` are public on
   GHCR, so the host pulls them without credentials. The old `velomine` package can be deleted.
3. **Branch protection on `main`:** require a pull request and the CI checks. Protect tags `v*` so only maintainers can
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

```bash
DEPLOY_HOST=$(tofu -chdir=infra output -raw app_public_ip) deploy/host/deploy.sh
```

`deploy.sh` reads `environments`, checks every file first, then:
- copies the compose files, scripts and systemd units;
- installs the settings with tight permissions (`app.env` 0640 for the deploy user, `db.env` and `restic.env` 0600 for
  root);
- writes each environment's `.env`: its images, its host names for Traefik, and `noindex` for dev and staging;
- starts Traefik and every environment that already has images, and enables the timers.

Run it again after changing a setting, a compose file, a timer or `environments`. A release does not need it.
`APEX_ENV` (default `demo`) names the environment that also answers `velomine.eu` and `www`.

## Moving the demo to this layout

The demo VPS still runs the old single-image layout: Caddy and one app container in `/opt/velomine/docker-compose.yml`,
data in `/srv/velomine/files` and `/srv/velomine/keys`, the image from the Scaleway registry. Move it once, after a
release tag has built the new images:

```bash
# On your machine: the old files become the demo environment's files.
cd deploy/host
mkdir -p envs/demo
mv velomine.env envs/demo/app.env
grep -E '^PG' backup.env > envs/demo/db.env
grep -vE '^PG' backup.env > restic.env && rm backup.env

# On the VPS: stop the old stack and timer, and move the data. Keep the Data Protection keys: they sign the sessions,
# and without them every member is signed out.
ssh deploy@<ip> 'set -e
  cd /opt/velomine && docker compose down
  sudo systemctl disable --now velomine-update.timer
  sudo rm -f /etc/systemd/system/velomine-update.service /etc/systemd/system/velomine-update.timer
  sudo mkdir -p /srv/velomine/demo /srv/velomine/backups/demo
  sudo mv /srv/velomine/files /srv/velomine/keys /srv/velomine/demo/
  sudo mv /srv/velomine/backups/velomine.dump /srv/velomine/backups/demo/ 2>/dev/null || true
  rm -f /opt/velomine/docker-compose.yml /opt/velomine/Caddyfile /opt/velomine/update-demo.sh /opt/velomine/restore-demo.sh /opt/velomine/.env
  sudo rm -f /etc/velomine/velomine.env /etc/velomine/backup.env'

# Install, then point the demo at the release (Deploy workflow, environment demo, the tag):
DEPLOY_HOST=<ip> deploy/host/deploy.sh
```

The demo is down from `docker compose down` until the new pair answers. Its database stays where it is. Older restic
snapshots of the demo carry the tag `demo` too, so the same retention applies to them.

## Turning on dev, staging or prod

1. `infra/`: resize the VPS, uncomment the environments' databases, users and DNS records, `tofu apply`
   (`infra/README.md`).
2. Here: uncomment the environment in `environments`; create `envs/<env>/app.env` and `db.env` (database and user
   `velomine_<env>`); run `deploy.sh`.
3. `.github/workflows/release.yml`: uncomment its job; add it to the choices in `deploy.yml`. Once prod is on, the demo
   job follows prod.

## Backups

`velomine-backup.timer` runs `backup.sh` nightly at 03:15 UTC. For each environment in `BACKUP_ENVS` (by default every
running environment except dev), it sends a `pg_dump -Fc` of the database, the ride files and the Data Protection key
ring to restic in the backup bucket, tagged with the environment (and the demo baseline for the demo). One environment
failing does not stop the others; the run fails at the end. The managed database also keeps its own 7-day backups.

Retention: prod 14 daily and 8 weekly snapshots, the others 7 daily and 4 weekly. With 30 days of bucket versioning,
deleted data leaves the backups within 90 days, as `docs/architecture.md` promises.

```bash
ssh deploy@<ip> 'systemctl list-timers velomine-backup.timer; sudo journalctl -u velomine-backup -n 50'
ssh deploy@<ip> 'sudo /opt/velomine/restore-check.sh demo'
```

`restore-check.sh <env>` restores the latest snapshot into a throwaway PostgreSQL container on the host and checks
that the dump loads and the files and keys are in it. It never touches the live database or files.

## Day to day

```bash
ssh deploy@<ip> 'journalctl -u velomine-update@demo -n 50 --no-pager'    # what the update timer did
ssh deploy@<ip> 'docker compose -p velomine-demo logs --tail=100'        # the server's and nginx's logs
ssh deploy@<ip> 'docker compose -f /opt/velomine/compose.traefik.yml logs --tail=50'   # Traefik and certificates
ssh deploy@<ip> 'cat /opt/velomine/demo/state/quarantined'               # a pair that failed its health check
```

### The demo

1. Open `https://demo.velomine.eu` and sign in as the admin from `envs/demo/app.env`.
2. Create the demo club, a coach and a few riders; upload `docs/samples/sample-ride.gpx` a few times; create a share
   link and check the coach view.
3. Take the baseline: `ssh deploy@<ip> 'sudo /opt/velomine/seed-baseline.sh'`.
4. Reset to it later: `ssh deploy@<ip> 'sudo DEMO_RESET=yes /opt/velomine/reset-demo.sh'`.

### Uptime and errors

- An external HTTPS check on `/health` (Better Stack or any monitor).
- Sentry EU: set `Velomine__Telemetry__Sentry__Dsn` and `__Environment` in `envs/<env>/app.env` and run `deploy.sh`.
- Alert on disk over 80 %, a backup older than 26 hours, TLS expiry, and a failed *Deploy* run.

## Troubleshooting

- **SSH times out while `http://<ip>/` answers.** Something on your network rate-limits new connections to port 22 for
  that address. Wait a few minutes and connect once; `deploy.sh` reuses one connection.
- **`404` from Traefik.** No router matches the host name: check `VELOMINE_ROUTER_RULE` in `/opt/velomine/<env>/.env`
  and that the web container is running and on the `proxy` network.
- **`502` from nginx.** The server is not answering: `docker compose -p velomine-<env> logs server`. Usually the
  database: check the private network and the user's privilege on its database.
- **No certificate.** Let's Encrypt must reach port 80 for every host name; check DNS and the Traefik log.
- **A deploy times out.** `journalctl -u velomine-update@<env>` says whether the host pulled the images, and whether it
  rolled back.

## Boundary

The demo holds synthetic accounts and sample rides only. Before a club's real member or health data goes on prod, move
prod to its own VPS and an HA database, revisit the Docker socket, and have the DPA, retention and a tested restore in
place.
