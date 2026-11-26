# Running the demo

The public demo runs on one Scaleway VPS: `demo.velomine.eu` serves the app. The same VPS runs a dev environment at `dev.velomine.eu`, for trying the newest version with real use. The presentation site is not on the VPS at all: GitHub Pages serves it at `velomine.eu`. Three compose projects, set up by hand, and GitHub has no access to the host:

| Directory | Project | Runs |
|-----------|---------|------|
| `/opt/velomine` | `velomine` | the demo: `docker-compose.yml` and `compose.hosted.yaml` |
| `/opt/velomine-dev` | `velomine-dev` | the dev environment: a second clone of the repository, the same two files |
| `/opt/velomine/deploy/traefik` | `traefik` | the one Traefik on ports 80 and 443, in front of both |

Each environment has its own database and volumes and is released on its own; Traefik reaches them over the external Docker network `proxy`. Every setting is explained in the README (*Settings you can change*).

## Where the versions come from

Every merge to `main` that passes CI and the smoke test becomes the next patch version: a tag `vX.Y.Z`, a GitHub Release with notes, and the images `ghcr.io/zenkraker/velomine-{server,web}:X.Y.Z`. The site is not a version of its own: GitHub Pages publishes it from `main` when `site/` changes. For a minor or major step, push a tag by hand (`git tag v0.3.0 && git push origin v0.3.0`); later merges count on from it. The repository's *Releases* page lists every version.

Work lands on the `dev` branch (features and fixes, by pull request); `main` is production. Every push to `dev` that passes CI and the smoke test is published as a prerelease, and the dev environment runs it. Its version is the one `main` will release next plus the run number, for example `0.1.31-dev.57` (images `ghcr.io/zenkraker/velomine-{server,web}:0.1.31-dev.57`, no `:0.1` tag), so it can never be mistaken for a production version and never takes a number `main` would use. GitHub keeps *Latest release* and the README links on the production versions.

Releasing to production is merging `dev` into `main` with a merge commit, never a fast-forward: a commit that already carries a version tag is not released again, so `main` needs a commit of its own. Merge `main` back into `dev` afterwards, so dev's next version counts from the new release. Dev is deployed by hand like the demo: set the new version in `/opt/velomine-dev/.env`. Never point the demo at a `-dev` version.

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

Traefik is not part of either environment, so releasing or restarting the demo or dev never takes the other down. Its `.env` is `/opt/velomine/deploy/traefik/.env` (`chmod 600`, never committed) with `VELOMINE_ACME_EMAIL`, nothing else. `demo.velomine.eu` and `dev.velomine.eu` have DNS pointing at the VPS. Traefik finds every route by the labels on an environment's web container, through the Docker socket (`compose.hosted.yaml`, from `VELOMINE_ENV` and `VELOMINE_HOST`).

```sh
cd /opt/velomine
sudo docker network create proxy                       # once
sudo docker compose -f deploy/traefik/compose.yaml up -d
```

After a change to `deploy/traefik/` (a new route, a new Traefik version), run the same `up -d` again. Its certificates live in the `traefik_letsencrypt` volume.

## The presentation site

The site is plain HTML in `site/`, published to GitHub Pages by `.github/workflows/pages.yml` on every push to `main` that touches it: `site/CNAME` holds `velomine.eu`, and `.nojekyll` keeps GitHub from processing the files. Nothing is built and no image is pushed. In the repository's *Settings → Pages*, the source is *GitHub Actions* and the custom domain is `velomine.eu` with *Enforce HTTPS*.

DNS for `velomine.eu` (Scaleway Domains and DNS) points at GitHub: the apex has four `A` records, `185.199.108.153`, `185.199.109.153`, `185.199.110.153` and `185.199.111.153`, and no other `A` record; `www` is a `CNAME` to `zenkraker.github.io.`, which GitHub redirects to the apex. The apex's `MX` and `TXT` records (Proton mail, SPF for Proton and Scaleway Transactional Email) stay as they are, and `demo` and `dev` keep their own `A` records to the VPS. The domain is verified in the GitHub account's *Settings → Pages* (a `TXT` record GitHub names), so no other account can claim it. The site's links to the app are absolute, `https://demo.velomine.eu/…`, and its two forms post there, so they work before and during a deploy of the demo.

A new page is a directory with an `index.html`, like the others: add its canonical and Open Graph tags, and its entry in `site/sitemap.xml` unless it is `noindex`.

## Set up the dev environment

1. Add the DNS record for `dev.velomine.eu`.
2. `sudo git clone <repository> /opt/velomine-dev`, check out the `v…-dev.N` tag to run, and write `/opt/velomine-dev/.env` (`chmod 600`) with:
   - `COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml`, `VELOMINE_VERSION`, `VELOMINE_ENV=dev` and `VELOMINE_HOST=dev.velomine.eu`
   - `VELOMINE__PUBLICURL=https://dev.velomine.eu`
   - `VELOMINE__ACCOUNTS__CLOUD=true`, because dev stands in for the cloud service: a new member verifies their own email (SMTP needed) and no admin approves them. Without it dev behaves like a self-hosted server and the sign-up page says an administrator must approve the account.
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
sudo nano deploy/traefik/.env                          # VELOMINE_ACME_EMAIL from the demo's .env, see above
sudo docker compose -f deploy/traefik/compose.yaml up -d
sudo nano .env                                         # COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml, VELOMINE_ENV=demo, VELOMINE_HOST=demo.velomine.eu, VELOMINE__FEEDBACK__SITEURL=https://velomine.eu; drop VELOMINE_DOMAIN, VELOMINE_SITE_DOMAIN and VELOMINE_ACME_EMAIL
sudo docker compose up -d --wait --remove-orphans
sudo docker volume rm velomine_letsencrypt             # the old certificates; Traefik asks Let's Encrypt for new ones
```

The names are unreachable for a few seconds while Traefik gets its certificates.

## Check it

- `https://velomine.eu` shows the site (GitHub Pages, independent of the VPS). Its *Sign in* opens `https://demo.velomine.eu/sign-in`, and its two forms (feedback, early access) answer on a page of the site.
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
| Traefik answers `404 page not found` for an environment's name | Traefik leaves out a container that is not healthy, or one without its labels: check `docker compose ps` in that environment and that `VELOMINE_ENV` and `VELOMINE_HOST` are set. |
| `Could not create the admin: Passwords must ...` | `VELOMINE__ADMIN__PASSWORD` needs 10 or more characters with an upper-case letter, a lower-case letter and a digit. |
| `Bind for 0.0.0.0:80 failed: port is already allocated` | Something else holds 80 or 443: `sudo ss -ltnp '( sport = :80 )'` and `sudo docker ps`. |
| No certificate, or the browser warns | the Traefik log above. Every name's DNS must point at the VPS, and ports 80 and 443 must be open in the security group. |
| `manifest unknown` / `not found` on pull | That version was never published. Check the Releases page and the Release workflow's run. |

## The `.env` on the VPS

The demo's lives in `/opt/velomine/.env`, with `chmod 600`, and is never committed. It holds:

- `COMPOSE_FILE=docker-compose.yml:compose.hosted.yaml`
- `VELOMINE_VERSION`, `VELOMINE_ENV=demo` and `VELOMINE_HOST=demo.velomine.eu`
- `VELOMINE__FEEDBACK__SITEURL=https://velomine.eu`, so the two forms of the site answer on a page of the site
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
- every night at 03:00 UTC deletes every club and every account except the server admins, then makes the accounts, the club, their rides and the demo rider's planned week again. Whatever a visitor changed is undone.
- catches up after downtime: when the server starts, or within a minute of being up, it makes the demo again if the last 03:00 UTC has passed since the demo was made.
- gives `demo-rider@velomine.eu` auto training on: a goal with the reason the rules give it and a week in progress, where the rides the seed wrote have ticked their sessions and one day was skipped. A visitor may change the setup, move a session, skip one day and make today easy; the night's reset puts the seeded week back. The scores are never written by the seed: a session carries a recipe and a day's minutes, so its score is the training code's, from the ride that was it.
- answers 403 (`code: demo_locked`) to the actions a visitor could use to lock out the others: registration, changing or resetting the password, deleting the account, two-factor sign-in, signing other sessions out, leaving the club, changing the join code and changing club roles, and turning auto training off. The list is `DemoLock.Refused`.
- answers the same 403 to skipping the **rest** of the training week (`restOfWeek` on the skip endpoint), which no route can carry: one visitor would leave the demo with no session at all until 03:00 UTC. A single day's skip, a move and making a day easy stay allowed, because they are the things worth trying. Off and the rest of the week are the two ways to empty the week, and both are refused for the same reason.
- sends no email except the feedback and early-access forms: SMTP may be set for it, but notification emails, the test email and verification emails are switched off, and email verification is never required to sign in.
