# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

## Status

Early development. Done so far: the server skeleton, the PostgreSQL data layer with migrations, and accounts (sign up with admin approval, password login with cookie or bearer token, refresh, roles admin/member/coach). Single sign-on with any OpenID Connect provider works and is tested end to end. Ride upload works: FIT, GPX and TCX files (also gzipped) are read in the background into rides with distance, moving time, climbing, speed, power, normalized power, heart rate and cadence. The Flutter web app is in place (sign in with a password, or single sign-on on the web; sign up, list and upload rides, admin approval of new accounts), tested in a real browser against the compose stack. Ride detail pages show the route on a map and charts of every signal. Bikes work: each member has bikes (with wheel circumference and the distance a used bike already had), parts with limits by distance, riding hours or months and a wear bar for each, a default bike that new rides are given, and a bike picker on every ride. Each member has a profile (FTP, weight, maximum heart rate, time zone and the day weeks start on), a Progress page with weekly, monthly and yearly totals and goals per week, month or year (distance, climbing, riding time or number of rides), and in-app notifications: a ride read, failed or uploaded twice, a part nearly or fully worn, and, for admins, an account waiting for approval. Email notifications are not built yet. Next: the phone recorder. The v1 scope, release plan and open questions are in [docs/design/v1-scope-and-architecture.md](docs/design/v1-scope-and-architecture.md).

## Run it on your computer

This starts the whole stack with one command: the server, the web app, PostgreSQL, and a small test sign-in provider for trying single sign-on. You do not need .NET, Flutter or PostgreSQL installed.

### What to install

| Install | Why | Notes |
|---------|-----|-------|
| **Docker** with Compose v2 | Builds and runs everything | Windows and macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (on Windows with the WSL 2 backend). Linux: Docker Engine plus the Compose plugin. The command must work as `docker compose` (with a space), not the old `docker-compose`. |
| **Git** | To get the code | Any recent version. |
| **Chrome, Edge or Firefox** | To open the web app | The single sign-on test uses the address `dex.localhost`, which these browsers send to your own machine. Safari is untested. |

Also needed:
- **About 8 GB of free disk and 4 GB of RAM for Docker.** The first build downloads the .NET SDK, the Flutter SDK and PostgreSQL, and compiles the web app inside Docker.
- **Internet access for the first build.** It reaches `mcr.microsoft.com`, `ghcr.io`, `docker.io`, `nuget.org`, `pub.dev` and `storage.googleapis.com` (the Flutter SDK). Behind a company proxy, set that up in Docker first.
- **Free ports 8080 (the app) and 5556 (the test sign-in provider).**
- **Apple Silicon Macs (arm64):** Flutter only ships a Linux x64 build, so the web build step runs emulated and takes longer. This has not been tried on an arm64 machine; if the build fails there, tell me what it prints.

### Start it

```
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
git checkout ccr-c5b2810d-ttm8ml
docker compose up --build
```

The first run takes roughly 5 to 10 minutes (later starts take seconds). It is ready when the log shows `Now listening on: http://0.0.0.0:8080`. Then open **http://localhost:8080**.

Stop it with Ctrl+C. `docker compose down` removes the containers and keeps your data; `docker compose down -v` also deletes the data (database and uploaded files), for a fresh start.

### What to try

1. **Sign in as the admin:** `admin@velomine.local` / `Velomine-dev-1`.
2. **Upload a ride:** press *Upload ride* and choose [docs/samples/sample-ride.gpx](docs/samples/sample-ride.gpx) (a synthetic 12-minute ride), or any FIT, GPX or TCX file from your own bike computer or from Strava or Garmin. The card shows *Reading the file…*, then distance, moving time, climbing, speed, power with normalized power, heart rate and cadence.
3. **Sign up as someone new:** sign out, choose *Create an account*, and register. The account waits for approval. Sign in as the admin, open *Accounts*, press *Approve*, then sign in as the new person.
4. **Try single sign-on:** sign out and press *Continue with Dex (local test)*. Log in on the provider's page with `rider@sso.test` / `password`. You come back told that the account is waiting for approval; approve it as the admin (step 3), then repeat the single sign-on and you are in.
5. **Open a ride:** press a ride card. The detail page shows the numbers, the route on a map, and a chart for each signal the ride has (elevation, speed, power, heart rate, cadence). Move the mouse over a chart, or touch and drag, to see the values at that moment on every chart and the position on the map. *Delete* removes the ride and its file.
6. **Add a bike:** open *Bikes*, press *Add bike*, give it a name and press *Save*. Open it and press *Add part*: choose *Chain* and the typical limit (4000 km) is filled in, which you can change. Upload a ride (step 2): it is given your default bike, so the bike's distance and the chain's wear grow. On the bike, *Replace* retires a part today and fits a new one; on a ride, the *Bike* menu changes which bike it was.
7. **Fill in your profile:** press your name at the top. Set your time zone (for example `Europe/Rome`) and the day your weeks start on; totals and goals follow them.
8. **See your progress:** open *Progress* for distance per week, month or year, and press *Add goal* (for example 100 km a week). A ride counts in the week, month and year it was ridden, not when it was uploaded: the sample ride is from 25 October 2026, so it moves a yearly goal (until 2027) but not this week's.
9. **Read your notifications:** the bell at the top counts unread ones: a ride that was read or failed, a part that is nearly worn (give a part a small limit to try it), and, for admins, a new account waiting for approval. Press one to open what it is about.
10. **Switch the theme:** the sun or moon button at the top chooses *Day*, *Night* or *Follow this device*. The choice is kept on that device (browser or phone).
11. **Look at the API:** the description is at http://localhost:8080/openapi/v1.json and the health check at http://localhost:8080/health.

### Settings you can change

Set them in a file named `.env` next to `docker-compose.yml` (for example `VELOMINE_PORT=9090`), or as environment variables.

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE_PORT` | `8080` | The port of the app. If you change it, also change the port in the redirect address in `deploy/dex/config.yaml`, or the single sign-on test breaks. |
| `POSTGRES_PASSWORD` | `velomine-dev` | The database password. Set it before the first start; the database keeps the old one afterwards. |
| `VELOMINE_ADMIN_EMAIL`, `VELOMINE_ADMIN_PASSWORD` | `admin@velomine.local`, `Velomine-dev-1` | The first admin. Only used while the server has no admin. |
| `VELOMINE_MAP_TILE_URL`, `VELOMINE_MAP_ATTRIBUTION` | empty | A map background for the ride map, for example `https://tile.openstreetmap.org/{z}/{x}/{y}.png` and `© OpenStreetMap contributors`. Empty means the route is drawn alone and your browser contacts no map server. Read the tile provider's usage rules first: OpenStreetMap's public servers are for light use only. |
| `Velomine__Accounts__RequireAdminApproval` | `true` | Set to `false` to let new accounts in without approval (add it under `environment:` of the `velomine` service). |

The defaults are for trying it out on your own machine only. Do not expose this setup to the internet as it is.

### If something goes wrong

| Problem | What to do |
|---------|-----------|
| `port is already allocated` | Something else uses 8080 or 5556. Stop it, or set `VELOMINE_PORT` (see above). |
| The build fails while downloading | Run it again; it keeps what it already downloaded. Check your internet or proxy settings. |
| The *Continue with Dex* page cannot be found | Use Chrome, Edge or Firefox. They resolve `dex.localhost` themselves; some other browsers and some tools do not. |
| The sign-in provider says the redirect address is wrong | You changed `VELOMINE_PORT` without editing `deploy/dex/config.yaml`. |
| You still see the old app after pulling new code | Run `docker compose up --build` again. |
| You forgot the admin password | The setting only applies while no admin exists. Run `docker compose down -v` to start over (this deletes the data). |
| Something else | `docker compose logs -f velomine` shows the server's log; add `postgres` or `dex` for those. |

### If you want to develop, not just run

Not needed for the steps above.

**Recommended: the Nix dev environment.** `flake.nix` provides every tool below at pinned versions (the Flutter release matches the `Dockerfile`), plus the Android SDK and emulator, Node for ponytail, CodeGraph and psql, without installing them into your system. With direnv the tools load when you enter the folder, and `just` runs the everyday commands (`just server`, `just web`, `just android`, `just check`). [docs/development.md](docs/development.md) explains how it works and walks through the one-time setup.

**Without Nix**, install these yourself:

| Install | For |
|---------|-----|
| **.NET SDK 10** | Building and testing the server: `dotnet test --solution Velomine.slnx` (the tests also need Docker; they start their own PostgreSQL and test provider). |
| **Flutter 3.47** (comes with Dart 3.13) | The app: `cd app && flutter test`. Run `flutter doctor` to see what else your target needs (Android Studio for Android, Xcode for iOS). |
| **Java 11 or newer, or Docker** | Regenerating the API client with `tools/generate-api-client.sh`. |
| **Claude Code with the ponytail plugin and CodeGraph** | Required for working on this repository; see [CLAUDE.md](CLAUDE.md). |

## Uploading rides

`POST /api/v1/rides/uploads` with a multipart `file` (FIT, GPX or TCX, up to 30 MB) and a bearer token. It answers `202` with the ride id; the file is read in the background, so poll `GET /api/v1/rides/{id}` until `status` is no longer `processing` (`ready`, `failed` with an `error` code such as `corrupt_file` or `not_cycling`, or `duplicate`). Send an `Idempotency-Key` header (the phone sends its own ride id) so a retry returns the same ride. `GET /api/v1/rides` lists your rides newest first (`?limit=` and `?cursor=`), `DELETE /api/v1/rides/{id}` removes a ride and its file. Files are kept as received under `Velomine__FilesPath`, so rides can be read again when a parser improves.

```
curl -H "Authorization: Bearer $TOKEN" -H "Idempotency-Key: my-ride-1" -F "file=@ride.fit" http://localhost:8080/api/v1/rides/uploads
```

## Single sign-on

Velomine signs people in through any OpenID Connect provider (Keycloak, Authentik, Entra ID, Google, ...). It is on when `Velomine__Sso__Authority` is set, together with `Velomine__Sso__ClientId` and `Velomine__Sso__ClientSecret`; `Velomine__Sso__DisplayName` is the button text, and `Velomine__Sso__AutoCreateUsers=false` limits sign-in to people who already have an account. In the provider, allow the redirect address `https://your-server/signin-oidc`. Behind a reverse proxy that ends TLS, set `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` so Velomine builds `https` addresses.

How it behaves: the first sign-in creates an account (waiting for admin approval unless `Velomine__Accounts__RequireAdminApproval=false`), or links to an existing account with the same email when the provider says the email is verified. The client starts at `GET /api/v1/accounts/sso/login?returnUrl=/path` and comes back to `returnUrl`, with `?sso_error=<reason>` when it did not work (`not_approved`, `email_not_verified`, `no_account`, `locked_out`, `no_email`, `failed`). `GET /api/v1/accounts/sso` says whether to show the button.

To try it locally, `docker compose up --build` also starts [Dex](docs/dependencies/dex.md), a small provider for development only. Open http://localhost:8080/api/v1/accounts/sso/login and sign in with `rider@sso.test` / `password`. The new account waits for approval, so approve it as the admin first (see above), then sign in again. Use Chrome or Firefox: they send `dex.localhost` to your own machine.

## The Flutter app

Code is in [app/](app/README.md). Its API client is generated: after changing an endpoint run `tools/generate-api-client.sh` (needs the .NET SDK, plus Docker or `OPENAPI_GENERATOR_JAR`) and commit the result. Checks: `cd app && dart format --set-exit-if-changed lib test && flutter analyze && flutter test`. The web build bundles its own rendering engine instead of fetching it from Google's CDN, so it works offline. One known gap: Flutter's default Roboto font is still fetched from Google's font host on first load; bundling it is a follow-up.

## Documents

- [Development environment](docs/development.md)
- [Architecture](docs/architecture.md)
- [v1 scope and architecture](docs/design/v1-scope-and-architecture.md)
- [Endurain feature analysis (v0.20.2)](docs/research/endurain-feature-analysis-v0.20.2.md)
- [Endurain porting comparison](docs/research/endurain-porting-comparison.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [CLAUDE.md](CLAUDE.md) first: it holds the rules for code, architecture and dependencies, including the mandatory ponytail plugin for Claude Code.
