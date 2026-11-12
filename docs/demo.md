# Running the demo

The public demo runs on one Scaleway VPS: `velomine.eu` serves the presentation site and `demo.velomine.eu` serves the app. It runs `docker-compose.yml` and `compose.demo.yaml` from `/opt/velomine`, set up by hand. GitHub has no access to the host. Every setting is explained in the README (*Settings you can change*).

## Where the versions come from

Every merge to `main` that passes CI and the smoke test becomes the next patch version: a tag `vX.Y.Z`, a GitHub Release with notes, and the images `ghcr.io/zenkraker/velomine-{server,web}:X.Y.Z`. For a minor or major step, push a tag by hand (`git tag v0.3.0 && git push origin v0.3.0`); later merges count on from it. The repository's *Releases* page lists every version.

## Deploy a version

Use this both for updates and for rollbacks.

```sh
cd /opt/velomine
sudo git fetch --tags && sudo git checkout vX.Y.Z     # compose files and routes from the same release
sudo nano .env                                        # VELOMINE_VERSION=X.Y.Z
sudo docker compose pull && sudo docker compose up -d --wait
```

`--wait` fails unless the web container is healthy, and its health check goes through nginx to the server. Migrations only add things for one release, so going back one version is safe.

## Check it

- `https://velomine.eu` shows the site. `/sign-in` there redirects to the demo.
- `https://demo.velomine.eu` opens the app.
- `curl -s https://demo.velomine.eu/api/v1/server` reports the version.
- `sudo docker compose ps` should show every container as `healthy` or `running`.

## When something is wrong

```sh
sudo docker compose logs --tail 50 server     # or web, traefik, postgres
```

| Symptom | Cause |
|---------|-------|
| The web container is unhealthy, or pages answer 502 | The server is not running; its log says why. |
| `Could not create the admin: Passwords must ...` | `VELOMINE__ADMIN__PASSWORD` needs 10 or more characters with an upper-case letter, a lower-case letter and a digit. |
| `Bind for 0.0.0.0:80 failed: port is already allocated` | Something else holds 80 or 443: `sudo ss -ltnp '( sport = :80 )'` and `sudo docker ps`. |
| No certificate, or the browser warns | `sudo docker compose logs traefik`. Both names' DNS must point at the VPS, and ports 80 and 443 must be open in the security group. |
| `manifest unknown` / `not found` on pull | That version was never published. Check the Releases page and the Release workflow's run. |

## The `.env` on the VPS

It lives in `/opt/velomine/.env`, with `chmod 600`, and is never committed. It holds:

- `COMPOSE_FILE=docker-compose.yml:compose.demo.yaml`
- `VELOMINE_VERSION`
- `VELOMINE_DOMAIN=demo.velomine.eu`, `VELOMINE_SITE_DOMAIN=velomine.eu` and `VELOMINE_ACME_EMAIL`
- `VELOMINE__PUBLICURL=https://demo.velomine.eu`
- `POSTGRES_PASSWORD`, `VELOMINE__ADMIN__EMAIL` and `VELOMINE__ADMIN__PASSWORD`
- telemetry: `VELOMINE__TELEMETRY__ENABLED=true` and `VELOMINE__TELEMETRY__ENVIRONMENT=demo`
- error reports: `VELOMINE__TELEMETRY__ERRORS__DSN` (the project's *Client Keys (DSN)* page)
- traces and logs: `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS` and `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` (the same page's *OpenTelemetry (OTLP)* tab)

After changing `.env`, run `sudo docker compose up -d --wait`; this recreates only the containers whose settings changed.

## Backups

Back up the database and both volumes together. Without the keys, every member is signed out and old links stop working.

```sh
cd /opt/velomine
sudo docker compose exec -T postgres pg_dump -Fc -U velomine velomine > velomine-$(date +%F).dump
for v in files keys; do
  sudo docker run --rm -v velomine_velomine-$v:/v -v "$PWD":/b alpine tar czf /b/$v-$(date +%F).tgz -C /v .
done
```

Copy the files off the VPS. A Scaleway volume snapshot is a cheap second copy.

## Demo data

`deploy/seed-demo.sql` adds bikes, rides and the rest to the club with the most members, and does nothing if that club already has data. Create the club and its members in the app first, copy the file to the VPS, and run:

```sh
sudo docker compose exec -T postgres psql -U velomine -d velomine -v ON_ERROR_STOP=1 --single-transaction < seed-demo.sql
```
