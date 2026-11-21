# Running the demo

The public demo runs on one Scaleway VPS: `velomine.eu` serves the presentation site and `demo.velomine.eu` serves the app. The same VPS runs a dev environment at `dev.velomine.eu`, for trying the newest version with real use. Three compose projects, set up by hand, GitHub has no access to the host:

| Directory | Project | Runs |
|-----------|---------|------|
| `/opt/velomine` | `velomine` | the demo: `docker-compose.yml` and `compose.hosted.yaml` |
| `/opt/velomine-dev` | `velomine-dev` | the dev environment: a second clone of the repository, the same two files |
| `/opt/velomine/deploy/traefik` | `traefik` | the one Traefik on ports 80 and 443, in front of both |

Each environment has its own database and volumes and is released on its own; Traefik reaches them over the external Docker network `proxy`. Every setting is explained in the README (*Settings you can change*).

## Where the versions come from

Every merge to `main` that passes CI and the smoke test becomes the next patch version: a tag `vX.Y.Z`, a GitHub Release with notes, and the images `ghcr.io/zenkraker/velomine-{server,web}:X.Y.Z`. For a minor or major step, push a tag by hand (`git tag v0.3.0 && git push origin v0.3.0`); later merges count on from it. The repository's *Releases* page lists every version.

Work lands on the `dev` branch (features and fixes, by pull request); `main` is production. Every push to `dev` that passes CI and the smoke test is published the same way, as a prerelease (so *Latest release* and the README links stay stable), and the dev environment runs it. Releasing to production is merging `dev` into `main` with a merge commit, never a fast-forward: a commit that already carries a version tag is not released again, so `main` needs a commit of its own. The count follows the tags in a commit's own history and skips any number a tag already holds, so numbers stay unique and rise on both branches; merge `main` back into `dev` after a release so the history stays together. Dev is deployed by hand like the demo: set the new version in `/opt/velomine-dev/.env`. Never point the demo at a version that is only on `dev`.

## Deploy a version

Use this both for updates and for rollbacks. The dev environment is the same, run from `/opt/velomine-dev` with its own `.env`; deploy a new version there first and give it to the demo once it behaves.

```sh
cd /opt/velomine
sudo git fetch --tags && sudo git checkout vX.Y.Z     # compose files and routes from the same release
sudo nano .env                                        # VELOMINE_VERSION=X.Y.Z
sudo docker compose pull && sudo docker compose up -d --wait
```

`--wait` fails unless the web container is healthy, and its health check goes through nginx to the server. Migrations only add things for one release, so going back one version is safe.

## Traefik

Traefik is not part of either environment, so releasing or restarting the demo or dev never takes the other down. Its `.env` is `/opt/velomine/deploy/traefik/.env` (`chmod 600`, never committed) with `VELOMINE_ACME_EMAIL`, `VELOMINE_DOMAIN=demo.velomine.eu`, `VELOMINE_SITE_DOMAIN=velomine.eu` and `VELOMINE_DEV_DOMAIN=dev.velomine.eu`. All three names have DNS pointing at the VPS.

```sh
cd /opt/velomine
sudo docker network create proxy                       # once
sudo docker compose -f deploy/traefik/compose.yaml up -d
```

After a change to `deploy/traefik/` (a new route, a new Traefik version), run the same `up -d` again. Its certificates live in the `traefik_letsencrypt` volume.

## Set up the dev environment

1. Add the DNS record for `dev.velomine.eu` and set `VELOMINE_DEV_DOMAIN` in Traefik's `.env`, then `up -d` Traefik as above.
2. `sudo git clone <repository> /opt/velomine-dev`, check out the tag to run (a prerelease from `dev`, for example), and write `/opt/velomine-dev/.env` (`chmod 600`) with:
   - `COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml`, `VELOMINE_VERSION` and `VELOMINE_PROXY_ALIAS=dev-web`
   - `VELOMINE__PUBLICURL=https://dev.velomine.eu`
   - `POSTGRES_PASSWORD`, `VELOMINE__ADMIN__EMAIL` and `VELOMINE__ADMIN__PASSWORD`, different from the demo's
   - no `VELOMINE__DEMO__ENABLED`: the demo remakes its data every night, dev keeps yours
   - `VELOMINE__TELEMETRY__ENABLED=true` and `VELOMINE__TELEMETRY__ENVIRONMENT=dev`, with the same error DSN as the demo if you like
3. `sudo docker compose pull && sudo docker compose up -d --wait`, then open `https://dev.velomine.eu`.

Dev holds data you care about: include it in the backups below, and read the release notes before you move it to a version with a migration.

## Moving an existing demo to this layout

The demo used to run its own Traefik from `compose.demo.yaml`. Once, on the host:

```sh
cd /opt/velomine
sudo docker compose rm -sf traefik                     # frees ports 80 and 443; run it before the checkout
sudo git fetch --tags && sudo git checkout vX.Y.Z      # a version with this layout
sudo docker network create proxy
sudo nano deploy/traefik/.env                          # the Traefik variables from the demo's .env, see above
sudo docker compose -f deploy/traefik/compose.yaml up -d
sudo nano .env                                         # COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml, VELOMINE_PROXY_ALIAS=demo-web; drop VELOMINE_DOMAIN, VELOMINE_SITE_DOMAIN and VELOMINE_ACME_EMAIL
sudo docker compose up -d --wait --remove-orphans
sudo docker volume rm velomine_letsencrypt             # the old certificates; Traefik asks Let's Encrypt for new ones
```

The names are unreachable for a few seconds while Traefik gets its certificates.

## Check it

- `https://velomine.eu` shows the site. `/sign-in` there redirects to the demo.
- `https://demo.velomine.eu` opens the app, and `https://dev.velomine.eu` opens the dev environment.
- `curl -s https://demo.velomine.eu/api/v1/server` (or the dev name) reports the version.
- `sudo docker compose ps` in each directory should show every container as `healthy` or `running`.

## When something is wrong

```sh
sudo docker compose logs --tail 50 server     # or web, postgres; run in the environment's directory
sudo docker compose -f deploy/traefik/compose.yaml logs --tail 50 traefik
```

| Symptom | Cause |
|---------|-------|
| The web container is unhealthy, or pages answer 502 | The server is not running; its log says why. |
| `Could not create the admin: Passwords must ...` | `VELOMINE__ADMIN__PASSWORD` needs 10 or more characters with an upper-case letter, a lower-case letter and a digit. |
| `Bind for 0.0.0.0:80 failed: port is already allocated` | Something else holds 80 or 443: `sudo ss -ltnp '( sport = :80 )'` and `sudo docker ps`. |
| No certificate, or the browser warns | the Traefik log above. Every name's DNS must point at the VPS, and ports 80 and 443 must be open in the security group. |
| `manifest unknown` / `not found` on pull | That version was never published. Check the Releases page and the Release workflow's run. |

## The `.env` on the VPS

The demo's lives in `/opt/velomine/.env`, with `chmod 600`, and is never committed. It holds:

- `COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml`
- `VELOMINE_VERSION` and `VELOMINE_PROXY_ALIAS=demo-web`
- `VELOMINE__PUBLICURL=https://demo.velomine.eu`
- `VELOMINE__DEMO__ENABLED=true` and `VELOMINE__ACCOUNTS__SIGNUPENABLED=false`
- `POSTGRES_PASSWORD`, `VELOMINE__ADMIN__EMAIL` and `VELOMINE__ADMIN__PASSWORD`
- telemetry: `VELOMINE__TELEMETRY__ENABLED=true` and `VELOMINE__TELEMETRY__ENVIRONMENT=demo`
- error reports: `VELOMINE__TELEMETRY__ERRORS__DSN` (the project's *Client Keys (DSN)* page)
- traces and logs: `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS` and `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` (the same page's *OpenTelemetry (OTLP)* tab)

After changing `.env`, run `sudo docker compose up -d --wait`; this recreates only the containers whose settings changed.

## Backups

Back up the database and both volumes together, in each environment's directory (the demo needs it less than dev: its data is remade every night). Without the keys, every member is signed out and old links stop working.

```sh
cd /opt/velomine
sudo docker compose exec -T postgres pg_dump -Fc -U velomine velomine > velomine-$(date +%F).dump
for v in files keys; do
  sudo docker run --rm -v velomine_velomine-$v:/v -v "$PWD":/b alpine tar czf /b/$v-$(date +%F).tgz -C /v .
done
```

In `/opt/velomine-dev` the volumes are named `velomine-dev_velomine-files` and `velomine-dev_velomine-keys`. Copy the files off the VPS. A Scaleway volume snapshot is a cheap second copy.

## Demo mode

`VELOMINE__DEMO__ENABLED=true` makes the server the demo. The code is in `src/Velomine.Server/Features/Demo/`, and the example data is `demo-seed.sql` there. In demo mode the server:

- keeps five accounts, all with the public password the presentation site prints: `demo-admin@velomine.eu` (the club owner), `demo-coach@velomine.eu`, `demo-rider@velomine.eu`, `demo-heart-rate@velomine.eu` (a heart-rate strap and no power meter, so the load comes from heart rate) and `demo-no-sensors@velomine.eu` (no power meter and no strap, so the watts are estimated and the load is how the ride felt). They share the club *Velo Club Demo*, and each has about three months of rides, with the original files, so export works.
- puts all its example data around Girona, Spain, as generated loops that follow no real track: the rides, the privacy zones, and a club library of four routes (*Sunday road loop*, *Gravel hills*, *Climb repeats*, *Coffee ride*) with two upcoming club rides on them. New example data stays in that area.
- every night at 03:00 UTC deletes every club and every account except the server admins, then makes the accounts, the club and the rides again. Whatever a visitor changed is undone.
- catches up after downtime: when the server starts, or within a minute of being up, it makes the demo again if the last 03:00 UTC has passed since the demo was made.
- answers 403 (`code: demo_locked`) to the actions a visitor could use to lock out the others: registration, changing or resetting the password, deleting the account, two-factor sign-in, signing other sessions out, leaving the club, changing the join code and changing club roles. The list is `DemoLock.Refused`.
- sends no email except the feedback and early-access forms: SMTP may be set for it, but notification emails, the test email and verification emails are switched off, and email verification is never required to sign in.
