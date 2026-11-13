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
| `VELOMINE__DEMO__ENABLED is on, but: ...` at start | Demo mode refuses to delete anything: the database holds other accounts, a demo address is an admin, or an admin is a club member. Use an empty database, or set `VELOMINE__DEMO__ENABLED=false`. |

## The `.env` on the VPS

It lives in `/opt/velomine/.env`, with `chmod 600`, and is never committed. It holds:

- `COMPOSE_FILE=docker-compose.yml:compose.demo.yaml`
- `VELOMINE_VERSION`
- `VELOMINE_DOMAIN=demo.velomine.eu`, `VELOMINE_SITE_DOMAIN=velomine.eu` and `VELOMINE_ACME_EMAIL`
- `VELOMINE__PUBLICURL=https://demo.velomine.eu`
- `VELOMINE__DEMO__ENABLED=true` and `VELOMINE__ACCOUNTS__SIGNUPENABLED=false`
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

## Demo mode

`VELOMINE__DEMO__ENABLED=true` makes the server the demo. The code is in `src/Velomine.Server/Features/Demo/`, and the example data is `demo-seed.sql` there. In demo mode the server:

- keeps three accounts, all with the public password the presentation site prints: `demo-admin@velomine.eu` (the club owner), `demo-coach@velomine.eu` and `demo-rider@velomine.eu`. They share the club *Velo Club Demo*, and each has about three months of rides, with the original files, so export works.
- every night at 03:00 UTC deletes every club and every account except the server admins, then makes the accounts, the club and the rides again. Whatever a visitor changed is undone.
- catches up after downtime: when the server starts, or within a minute of being up, it makes the demo again if the last 03:00 UTC has passed since the demo was made.
- answers 403 (`code: demo_locked`) to the actions a visitor could use to lock out the others: registration, changing or resetting the password, deleting the account, two-factor sign-in, signing other sessions out, leaving the club, changing the join code and changing club roles. The list is `DemoLock.Refused`.
- refuses to start, rather than delete anything, when it finds:
  - `A demo account is a server admin. Use another address for VELOMINE__ADMIN__EMAIL: the demo accounts are public.`
  - `This server has accounts that are not demo accounts. Demo mode deletes every account but the admins each night, so it only starts on an empty server or on a demo.`
  - `A server admin is a member of a club. Demo mode deletes every club each night, so it only starts on an empty server or on a demo.`
