# Velomine hosts

How the hosted environments run. A self-hoster needs none of this: `docker-compose.yml` at the repository root is enough.

| Environment | Address | Host | Gets a new image |
|-------------|---------|------|------------------|
| dev | `https://dev.velomine.eu` | envs VPS | every merge to `main` |
| staging | `https://staging.velomine.eu` | envs VPS | every tag `vX.Y.Z` |
| prod | `https://app.velomine.eu` | envs VPS | the same digest, after an approval |
| demo | `https://demo.velomine.eu` | demo VPS | the same digest, after prod |

`infra/` creates the machines, databases, DNS and backup bucket. This folder holds what runs on them.

## How a release moves

```
PR ──► CI (.github/workflows/ci.yml): format, analyze, tests, generated files, API client, pinned versions
merge to main ──► Release: CI ─► build ─► smoke test ─► push ghcr.io/zenkraker/velomine:sha-<commit> ─► dev
tag vX.Y.Z    ──► Release: CI ─► build ─► smoke test ─► push :X.Y.Z ─► staging ─► (approve) prod ─► demo
```

- **One image, many environments.** Staging, prod and demo run the same digest. A deploy points the environment's tag
  (`:staging`, `:prod`, ...) at that digest; it never rebuilds.
- **The host pulls.** `velomine-update@<env>.timer` runs `update.sh <env>` every minute. It pulls the environment's tag,
  restarts the app, and waits up to two minutes for `/health`. If the new image never becomes healthy, it **rolls back
  to the digest that was running before** and quarantines the bad one. So GitHub holds no SSH key and no host secret.
- **The workflow checks.** The deploy job waits until `GET /api/v1/server` reports the new commit (`version` ends in
  `+<short sha>`). A rolled-back image shows in GitHub as a failed deployment.
- **Roll back** by running the *Deploy* workflow by hand with the environment and the previous tag. Migrations are
  backward-compatible for one release, so the previous image runs on the migrated schema.

## Isolation

Each environment is its own compose project (`velomine-<env>`), with its own:

- Docker network (`velomine-<env>`), shared only with Caddy, so no environment can reach another's container;
- database and database user, which cannot connect to another environment's database;
- settings and secrets in `/etc/velomine/<env>/`, and data in `/srv/velomine/<env>/` (ride files, Data Protection keys);
- Sentry environment name and host name; dev and staging send `X-Robots-Tag: noindex`.

They share the VPS (CPU, memory, disk) and the database instance. Each app has `mem_limit: 850m`. A runaway dev build
can still slow prod down: move prod to its own VPS and database before a club's real data depends on it.

## One-time setup

### GitHub

1. **Environments** (*Settings → Environments*): create `dev`, `staging`, `prod` and `demo`. On each, set the variable
   `PUBLIC_URL` (for example `https://staging.velomine.eu`). On `prod` and `demo`, add required reviewers. On every
   environment, limit deployments to the branch `main` and tags `v*` (a hand-started *Deploy* run comes from `main`;
   the workflow itself refuses anything but a release image for staging, prod and demo).
2. **The package:** after the first release run, open *Packages → velomine → Package settings*, make it **public**
   (hosts pull without credentials) and link it to the repository.
3. **Branch protection on `main`:** require a pull request and the CI checks (*Server*, *App*, *API client matches the
   server*, *Pinned versions agree*). Protect tags `v*` (*Settings → Rules → Tag rulesets*) so only maintainers can
   start a release.
4. Delete the old repository secrets `SCW_REGISTRY_ACCESS_KEY` and `SCW_REGISTRY_SECRET_KEY`: nothing uses them now.

### Infrastructure

Follow `infra/README.md`, then `tofu output`.

### Settings and secrets

On your machine, in this folder (all git-ignored):

```bash
for env in dev staging prod; do
  mkdir -p envs/$env
  cp envs/app.env.example envs/$env/app.env
  cp envs/db.env.example  envs/$env/db.env
done
cp restic.env.example restic.env
```

Fill them from `tofu output` and your secret store: the database host is `envs_db_host`, the database and user are
`velomine_<env>`, and the passwords are the ones you gave OpenTofu. Use a different admin password per environment.

### Install a host

```bash
DEPLOY_HOST=$(tofu -chdir=infra output -raw envs_public_ip) ENVS="dev staging prod" deploy/host/deploy.sh
DEPLOY_HOST=$(tofu -chdir=infra output -raw app_public_ip)  ENVS="demo" APEX_ENV=demo deploy/host/deploy.sh
```

`deploy.sh` checks every file first, then copies compose, Caddy, the scripts and the systemd units, installs the
settings with tight permissions (`app.env` 0640 for the deploy user, `db.env` and `restic.env` 0600 for root), writes
one Caddy site per environment from its `Velomine__PublicUrl`, starts Caddy and every environment that already has an
image, and enables the timers. Run it again after changing a setting, compose, Caddy or a timer. A release does not
need it.

`APEX_ENV` names the environment that also answers `velomine.eu` and `www.velomine.eu`. Keep it the same as `apex_env`
in OpenTofu, and pass it to the host that runs that environment only.

## Moving the demo to this layout

The demo host still runs the old single-project layout (`/opt/velomine/docker-compose.yml`, data in
`/srv/velomine/files` and `/srv/velomine/keys`, image from the Scaleway registry). Move it once:

```bash
# On your machine: the old files become the demo environment's files.
cd deploy/host
mkdir -p envs/demo
mv velomine.env envs/demo/app.env
grep -E '^PG' backup.env > envs/demo/db.env
grep -vE '^PG' backup.env > restic.env && rm backup.env

# On the demo host: stop the old stack and timer, and move the data. Keep the Data Protection keys: they sign the
# sessions, and without them every member is signed out.
ssh deploy@<demo-ip> 'set -e
  cd /opt/velomine && docker compose down
  sudo systemctl disable --now velomine-update.timer
  sudo rm -f /etc/systemd/system/velomine-update.service /etc/systemd/system/velomine-update.timer
  sudo mkdir -p /srv/velomine/demo
  sudo mv /srv/velomine/files /srv/velomine/keys /srv/velomine/demo/
  sudo mkdir -p /srv/velomine/backups/demo
  sudo mv /srv/velomine/backups/velomine.dump /srv/velomine/backups/demo/ 2>/dev/null || true
  rm -f /opt/velomine/docker-compose.yml /opt/velomine/update-demo.sh /opt/velomine/restore-demo.sh /opt/velomine/.env
  sudo rm -f /etc/velomine/velomine.env /etc/velomine/backup.env'

# Then run a demo release (Deploy workflow, environment demo, the latest tag) and install:
DEPLOY_HOST=<demo-ip> ENVS="demo" APEX_ENV=demo deploy/host/deploy.sh
```

The demo is down from `docker compose down` until the new install answers. Its database stays where it is. Older
restic snapshots of the demo carry the tag `demo` too, so the same retention applies to them.

## Backups

`velomine-backup.timer` runs `backup.sh` nightly at 03:15 UTC. For each environment in `BACKUP_ENVS` (by default every
environment on the host except dev), it sends a `pg_dump -Fc` of the database, the ride files and the Data Protection
key ring to restic in the backup bucket, tagged with the environment (and the demo baseline for the demo). One
environment failing does not stop the others; the run fails at the end. The managed databases also keep their own
7-day backups.

Retention: prod 14 daily and 8 weekly snapshots, the others 7 daily and 4 weekly. With 30 days of bucket versioning,
deleted data leaves the backups within 90 days, as `docs/architecture.md` promises.

```bash
ssh deploy@<ip> 'systemctl list-timers velomine-backup.timer; sudo journalctl -u velomine-backup -n 50'
ssh deploy@<ip> 'sudo /opt/velomine/restore-check.sh prod'
```

`restore-check.sh <env>` restores the latest snapshot into a throwaway PostgreSQL container on the host and checks
that the dump loads and the files and keys are in it. It never touches the live database or files.

## Day to day

```bash
ssh deploy@<ip> 'journalctl -u velomine-update@prod -n 50 --no-pager'   # what the update timer did
ssh deploy@<ip> 'docker compose -p velomine-prod logs --tail=100'       # the app's log
ssh deploy@<ip> 'cat /opt/velomine/prod/state/quarantined'              # an image that failed its health check
```

### The demo

1. Open `https://demo.velomine.eu` and sign in as the admin from `envs/demo/app.env`.
2. Create the demo club, a coach and a few riders; upload `docs/samples/sample-ride.gpx` a few times; create a share
   link and check the coach view.
3. Take the baseline: `ssh deploy@<demo-ip> 'sudo /opt/velomine/seed-baseline.sh'`.
4. Reset to it later: `ssh deploy@<demo-ip> 'sudo DEMO_RESET=yes /opt/velomine/reset-demo.sh'`.

### Uptime and errors

- An external HTTPS check on each environment's `/health` (Better Stack or any monitor).
- Sentry EU: set `Velomine__Telemetry__Sentry__Dsn` and `__Environment` in `envs/<env>/app.env` and run `deploy.sh`.
- Alert on disk over 80 %, a backup older than 26 hours, TLS expiry, and a failed *Deploy* run.

## Troubleshooting

- **SSH times out while `http://<ip>/` answers "connection refused".** Something on your network rate-limits new
  connections to port 22 for that address. Wait a few minutes and connect once; `deploy.sh` reuses one connection.
- **`502` from Caddy.** The app is up but unhealthy: `docker compose -p velomine-<env> logs app`. Usually the database:
  check the private network and the user's privilege on its database.
- **A deploy times out.** `journalctl -u velomine-update@<env>` says whether the host pulled the image, and whether it
  rolled back.

## Boundary

Dev, staging and demo hold synthetic accounts and sample rides only. Prod shares its VPS and database instance with dev
and staging; before a club's real member or health data goes on it, move prod to its own VPS and an HA database, and
have the DPA, retention and a tested restore in place.
