# Velomine demo deployment

One app container, one Caddy container, one managed PostgreSQL database. No
tenancy, no Kubernetes, no load balancer.

## 1. Build and push the image

```bash
docker login rg.nl-ams.scw.cloud
docker buildx build --platform linux/amd64 \
  --build-arg VERSION=demo \
  --build-arg REVISION="$(git rev-parse --short HEAD)" \
  -t rg.nl-ams.scw.cloud/<namespace>/app:demo --push .
```

`<namespace>` is the `registry_namespace` output from OpenTofu.

## 2. Provision the infrastructure

Follow `infra/demo/README.md`. Then collect the outputs:

```bash
cd infra/demo
tofu output
```

## 3. Create the environment files

```bash
cp deploy/demo/velomine.env.example deploy/demo/velomine.env
cp deploy/demo/backup.env.example deploy/demo/backup.env
```

Fill both from the Terraform outputs and your secret store. The database host is
the private IP, not the public one. `velomine.env` and `backup.env` are ignored
by Git.

## 4. Deploy

```bash
DEPLOY_HOST=<public-ip> \
VELOMINE_IMAGE=rg.nl-ams.scw.cloud/<namespace>/app:demo \
./deploy/demo/deploy.sh
```

The script copies the compose file and Caddyfile, installs the environment
files with `0600`, pulls the image, starts Caddy and the app, installs the
backup and update timers, and waits for `https://demo.velomine.eu/health`.

If the registry is private, also set `REGISTRY_USER` and `REGISTRY_PASSWORD`
(or use a public namespace for the demo).

## Releases (CI)

This is a one-time install plus a release loop that needs no inbound SSH.

- `.github/workflows/demo-image.yml` runs the tests first and only builds when
  they pass: `dotnet test` for the server, then `build_runner`, `dart format
  --set-exit-if-changed`, `flutter analyze` and `flutter test` for the web app.
  It then pushes `rg.nl-ams.scw.cloud/velomine-demo/app:demo` and `:<git sha>`
  from the default branch. Actions are pinned to commit SHAs and the workflow
  holds `contents: read` only.
- It needs two repository secrets: `SCW_REGISTRY_ACCESS_KEY` and
  `SCW_REGISTRY_SECRET_KEY`, from an IAM application with
  `ContainerRegistryFullAccess` (not the account key).
- The host runs `velomine-update.timer` every five minutes: it pulls `:demo`,
  recreates the app and waits up to two minutes for `/health`. If the new image
  never becomes healthy it **rolls back to the digest that was running before**
  and records the bad digest in `/opt/velomine/state/quarantined`, so the timer
  does not retry it every five minutes. A later, different push is still
  deployed.

So a release is: merge to the default branch → tests → image pushed → the host
picks it up within five minutes and rolls back on its own if the image is bad.
`deploy.sh` is for the first install and for changes to compose, Caddy or the
timers.

Check what happened on the host with:

```bash
ssh deploy@<public-ip> 'journalctl -u velomine-update.service -n 50 --no-pager'
```

## 5. Create the demo

1. Open `https://demo.velomine.eu`.
2. Sign in as the admin from `velomine.env`.
3. Create the demo club, a coach and a few riders.
4. Upload `docs/samples/sample-ride.gpx` a few times.
5. Create a share link and check the coach view.

Then take the baseline used by the reset script:

```bash
ssh deploy@<public-ip> 'sudo /opt/velomine/seed-baseline.sh'
```

## Troubleshooting

- **SSH times out from your machine while `http://<ip>/` answers "connection
  refused".** The host is fine: something on your network is rate-limiting new
  connections to port 22 for that address (a burst of SSH attempts trips it).
  Wait a few minutes, stop retrying in a loop, and connect once.
- **`502` from Caddy.** The app container is up but unhealthy; `docker compose
  logs app` shows why. Usually the database: check the private network is
  attached and `scaleway_rdb_privilege` granted the app user access.

## Backups

The timer runs `backup.sh` nightly at 03:15 UTC. It dumps PostgreSQL and sends
the dump, ride files, Data Protection keys and the demo baseline to restic in
the Scaleway Object Storage bucket.

Check it:

```bash
ssh deploy@<public-ip> 'systemctl list-timers velomine-backup.timer'
ssh deploy@<public-ip> 'sudo journalctl -u velomine-backup.service -n 50'
```

Verify a restore into a scratch database:

```bash
ssh deploy@<public-ip> 'sudo /opt/velomine/restore-demo.sh'
```

The live database is not touched.

## Reset the demo

After the baseline exists:

```bash
ssh deploy@<public-ip> 'sudo DEMO_RESET=yes /opt/velomine/reset-demo.sh'
```

This stops the app, restores the baseline database and files, keeps the Data
Protection keys, and starts the app again.

## Uptime and errors

- Better Stack (or any external monitor): HTTPS check on
  `https://demo.velomine.eu/health`.
- Sentry EU: set `Velomine__Telemetry__Sentry__Dsn` in `velomine.env` and
  redeploy. With an empty DSN, telemetry stays off.
- Alert on disk 80%, backup age over 26 hours, and TLS expiry.

## Boundary

This is a demo. It has no DPA, no tenancy, no real-member-data retention policy
and no production hardening. Use synthetic accounts and sample rides. Do not put
a club's real member or health data on it until the DPA, retention, rate limits
and restore process exist.

## What is intentionally missing

Tenancy, tenant catalog, per-tenant migrations, HA, load balancer, block volume,
Kubernetes, CI/SBOM, billing, licence, app-store work and DR drills.
