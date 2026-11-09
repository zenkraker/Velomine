# Velomine

Cycling-only training platform for clubs and teams. Cloud is the default: one shared deployment with a database per club. Self-hosting runs the same image as a single-tenant instance. No feature paywall; every member owns their data.

## Status

Early development. Done so far: the server skeleton, the PostgreSQL data layer with migrations, and accounts (sign up with admin approval, password login with cookie or bearer token, refresh, roles club admin/member/coach). Password reset works by email link, or by a one-time link a club admin makes when the server has no email. Single sign-on works on the web with any OpenID Connect provider, and on the phone as a public client with PKCE, tested end to end. Ride upload works: FIT, GPX and TCX files (also gzipped) are read in the background into rides with distance, moving time, climbing, speed, power, normalized power, heart rate and cadence. The Flutter web app is in place (sign in with a password, or single sign-on on the web; sign up, list and upload rides, admin approval of new accounts), tested in a real browser against the compose stack. Ride detail pages show the route on a map and charts of every signal. Rides also carry four optional dimensions (surface, e-bike, indoor/virtual, commute) inferred from FIT and GPX, editable by the member and filterable in the list, and laps read from FIT and TCX as a table that shades the charts and the map. A new ride takes a bike of the matching kind (road, gravel, mountain, e-bike, track or city) and falls back to the member's single default bike; the Progress totals and training dashboard can be filtered by surface. Bikes work: each member has bikes (with wheel circumference and the distance a used bike already had), parts with limits by distance, riding hours or months and a wear bar for each, a default bike that new rides are given, and a bike picker on every ride. Each member has a profile (FTP, weight, year of birth with an estimated maximum heart rate, time zone and the day weeks start on); the language chosen on one device follows the account to every device. A Progress page with weekly, monthly and yearly totals and goals per week, month or year (distance, climbing, riding time or number of rides), and in-app notifications: a ride read, failed or uploaded twice, a part nearly or fully worn, and, for club admins, an account waiting for approval. Accounts no longer need a club: a rider can record and analyse on their own. The current single-tenant build also lets a rider see clubs on the same server that opted into nearby discovery (sorted by distance from the device or a point saved on it) and ask one to join; the owner approves or declines. In the cloud model each club has its own database, so discovery and joining move to the opt-in inter-club directory (v2). Club admins have an Admin screen: every account (roles, lock, delete), the settings they can change (sign-up and approval), a server overview and a test email. Notifications can also go out by email when the server has an SMTP server set up, with a switch in each member's profile. Members can download all their data as a ZIP (with every original ride file) and delete their account with everything in it. The phone app asks for the club's server address once and keeps the member signed in across restarts with a refresh token in the device's secure storage. On Android the phone recorder now records a GPS ride with the screen off, connects to a paired Bluetooth heart-rate strap, keeps the raw samples on the phone, assembles a FIT file when the ride stops, uploads it to the server automatically (with retries) and lists it on the Record tab. It also pauses itself after three seconds at walking pace or slower and resumes after two seconds above 0.1 km/h, writing the pause into the FIT file; the start card asks for the ride type and whether it was e-assisted, and both are written into the FIT session. the server now leaves paused time and the jump across a stop out of moving time, averages and distance. Uploads continue through a background worker when the app is not open. Ride pages show heart-rate and power zones with intensity factor, TSS and TRIMP, and Progress adds a training dashboard (30/90/365 days) with daily load and fitness, fatigue and form. Progress also shows a power curve with FTP and VO2max estimates, a readiness view built from form, recent load and the daily check-in, and the check-in itself (fatigue, soreness, mood, stress, motivation) with RPE and notes on each ride; coaches see shared wellbeing and the power curve, but never the notes. Sensors pair directly over standard Bluetooth LE, without a vendor app or account; speed, cadence and power sensors are being integrated, and the iOS recorder is next. The presentation site is served by the server at `/`, with Home, Status, Pricing and Contact pages; the web app opens from *Sign in*. The v1 scope, release plan and open questions are in [docs/design/v1-scope-and-architecture.md](docs/design/v1-scope-and-architecture.md).

## Deployment model

Cloud is the default: one shared Velomine deployment with one PostgreSQL database and role per club on a managed cluster. Self-hosting runs the same image as a single-tenant instance with one database and one file volume. Both plans have the same features; only the operator differs. The cloud tenant catalog, per-club onboarding and offline licensing are the next architectural step; the commands below run the single-tenant mode.

## Run it on your computer

This starts the single-tenant (self-host) mode with one command: the server, the web app, PostgreSQL, and a small test sign-in provider for trying single sign-on. You do not need .NET, Flutter or PostgreSQL installed.

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

The first run takes roughly 5 to 10 minutes (later starts take seconds). It is ready when the log shows `Now listening on: http://0.0.0.0:8080`. Then open **http://localhost:8080** — the presentation site. Press *Sign in* to open the web app.

Stop it with Ctrl+C. `docker compose down` removes the containers and keeps your data; `docker compose down -v` also deletes the data (database and uploaded files), for a fresh start.

### What to try

1. **Sign in as the admin:** from the site, press *Sign in* and use `admin@velomine.local` / `Velomine-dev-1`.
2. **Upload a ride:** press *Upload ride* and choose [docs/samples/sample-ride.gpx](docs/samples/sample-ride.gpx) (a synthetic 12-minute ride), or any FIT, GPX or TCX file from your own bike computer or from Strava or Garmin. The card shows *Reading the file…*, then distance, moving time, climbing, speed, power with normalized power, heart rate and cadence.
3. **Sign up as someone new:** sign out, choose *Create an account*, and register. The account waits for approval. Sign in as the admin, open *Admin*, press *Approve*, then sign in as the new person.
4. **Try single sign-on:** sign out and press *Continue with Dex (local test)*. Log in on the provider's page with `rider@sso.test` / `password`. You come back told that the account is waiting for approval; approve it as the admin (step 3), then repeat the single sign-on and you are in.
5. **Open a ride:** press a ride card. The detail page shows the numbers, the route on a map, and a chart for each signal the ride has (elevation, speed, power, heart rate, cadence). Move the mouse over a chart, or touch and drag, to see the values at that moment on every chart and the position on the map. *Delete* removes the ride and its file.
6. **Add a bike:** open *Bikes*, press *Add bike*, give it a name and press *Save*. Open it and press *Add part*: choose *Chain* and the typical limit (4000 km) is filled in, which you can change. Upload a ride (step 2): it is given a bike of the matching kind, or your default bike when that kind has none, so the bike's distance and the chain's wear grow. On the bike, *Replace* retires a part today and fits a new one; on a ride, the *Bike* menu changes which bike it was.
7. **Fill in your profile:** press your name at the top. Set your time zone (for example `Europe/Rome`) and the day your weeks start on; totals and goals follow them.
8. **See your progress:** open *Progress* for distance per week, month or year, and press *Add goal* (for example 100 km a week). Filter by surface to see one kind of ride; goals always count every ride. A ride counts in the week, month and year it was ridden, not when it was uploaded: the sample ride is from 25 October 2026, so it moves a yearly goal (until 2027) but not this week's.
9. **Read your notifications:** the bell at the top counts unread ones: a ride that was read or failed, a part that is nearly worn (give a part a small limit to try it), and, for club admins, a new account waiting for approval. Press one to open what it is about.
10. **Switch the theme:** the sun or moon button at the top chooses *Day*, *Night* or *Follow this device*. The choice is kept on that device (browser or phone).
11. **Manage accounts as the admin:** open *Admin*. *Accounts* lists everyone: change roles, lock or unlock an account (a locked account cannot sign in), or delete it with all its data. *Settings* changes sign-up and approval, and shows email and single sign-on read-only. *Overview* shows totals. To try email, start a mail catcher such as [Mailpit](https://mailpit.axllent.org/) and set `VELOMINE__SMTP__HOST`, `VELOMINE__SMTP__PORT=1025`, `VELOMINE__SMTP__SECURITY=none` and `VELOMINE__SMTP__FROM`, then press *Send a test email to me*.
12. **Take your data, or leave:** on your profile, *Download my data* gives a ZIP with your details, bikes, goals, rides and every ride file exactly as you uploaded it (open it with any unzip tool; `README.txt` explains the files). *Delete my account* asks for your password (or your email, if you signed in with single sign-on) and then removes the account, its rides and the ride files for good.
13. **Look at the API:** the description is at http://localhost:8080/openapi/v1.json and the health check at http://localhost:8080/health.
14. **Reset a password:** sign out, press *Forgot password?* and enter an address. With email set up, the link arrives by mail (it works once and expires in 30 minutes). Without email, sign in as the admin, open *Admin*, *Accounts*, and use *Reset password* to make a one-time link yourself. Changing a password from *Profile* signs out every session, including the current one. The link is built from `VELOMINE__PUBLICURL`, so set it to the address members open (for example `https://club.example`) before exposing the server; it never trusts the incoming Host header.

### Settings you can change

Set them in a file named `.env` next to `docker-compose.yml` (for example `VELOMINE_PORT=9090`), or as environment variables. Infrastructure environment variables are upper case, with `__` for nested settings (`VELOMINE__SMTP__HOST`); the application's internal configuration keys keep their .NET spelling (`Velomine:Smtp:Host`).

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE_PORT` | `8080` | The port of the app. If you change it, also change the port in the redirect address in `deploy/dex/config.yaml`, or the single sign-on test breaks, and set `VELOMINE__PUBLICURL` (used by the compose stack) to the same address. |
| `POSTGRES_PASSWORD` | `velomine-dev` | The database password. Set it before the first start; the database keeps the old one afterwards. |
| `VELOMINE__ADMIN__EMAIL`, `VELOMINE__ADMIN__PASSWORD` | `admin@velomine.local`, `Velomine-dev-1` | The first admin. Only used while the server has no admin. |
| `VELOMINE__PUBLICURL` | `http://localhost:8080` | The address members open, used in password reset emails. Set it to the club's public address (for example `https://club.example`); the incoming Host header is never used. |
| `VELOMINE__MAP__TILEURL`, `VELOMINE__MAP__ATTRIBUTION` | OpenStreetMap | Maps are always on. Set these (under `environment:` of the `velomine` service) to use a private tile server instead; an empty or unusable address falls back to OpenStreetMap. Read the provider's usage rules first: OpenStreetMap's public servers are for light use only. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `true` | Set to `false` to let new accounts in without approval (add it under `environment:` of the `velomine` service). An admin can also change this, and sign-up on or off, in the app (*Admin*, *Settings*); a saved value overrides the environment. |
| `VELOMINE__SMTP__HOST`, `VELOMINE__SMTP__FROM` | empty | Email is on when both are set. `From` is the sender, for example `Velomine <velomine@club.example>`. |
| `VELOMINE__SMTP__PORT`, `VELOMINE__SMTP__SECURITY` | `587`, `starttls` | `Security` is `starttls` (port 587), `ssl` (port 465) or `none` (a local relay only). |
| `VELOMINE__SMTP__USER`, `VELOMINE__SMTP__PASSWORD` | empty | The SMTP login, if the server needs one. **Environment only, by design:** they are never stored in the database or shown in the app, and neither are the single sign-on secrets. The admin Settings page shows email and single sign-on read-only, with a *Send a test email* button. |

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
| **Claude Code or OpenCode, with the ponytail plugin, plus CodeGraph** | Required for working on this repository; see [AGENTS.md](AGENTS.md). |

## Uploading rides

`POST /api/v1/rides/uploads` with a multipart `file` (FIT, GPX or TCX, up to 30 MB) and a bearer token. It answers `202` with the ride id; the file is read in the background, so poll `GET /api/v1/rides/{id}` until `status` is no longer `processing` (`ready`, `failed` with an `error` code such as `corrupt_file` or `not_cycling`, or `duplicate`). Send an `Idempotency-Key` header (the phone sends its own ride id) so a retry returns the same ride. `GET /api/v1/rides` lists your rides newest first (`?limit=` and `?cursor=`), `DELETE /api/v1/rides/{id}` removes a ride and its file. Files are kept as received under `VELOMINE__FILESPATH`, so rides can be read again when a parser improves.

```
curl -H "Authorization: Bearer $TOKEN" -H "Idempotency-Key: my-ride-1" -F "file=@ride.fit" http://localhost:8080/api/v1/rides/uploads
```

## Single sign-on

Velomine signs people in through any OpenID Connect provider (Keycloak, Authentik, Entra ID, Google, ...). It is on when `VELOMINE__SSO__AUTHORITY` is set, together with `VELOMINE__SSO__CLIENTID` and `VELOMINE__SSO__CLIENTSECRET`; `VELOMINE__SSO__DISPLAYNAME` is the button text, and `VELOMINE__SSO__AUTOCREATEUSERS=false` limits sign-in to people who already have an account. In the provider, allow the redirect address `https://your-club-host/signin-oidc`. The phone app signs in through the phone's browser and is handed back through its own link, so nothing else needs setting up. Behind a reverse proxy that ends TLS, set `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` so Velomine builds `https` addresses. In cloud, the platform supplies a default provider and each club may override it; a self-host instance configures its own.

How it behaves: the first sign-in creates an account (waiting for admin approval unless `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL=false`), or links to an existing account with the same email when the provider says the email is verified. The client starts at `GET /api/v1/accounts/sso/login?returnUrl=/path` and comes back to `returnUrl`, with `?sso_error=<reason>` when it did not work (`not_approved`, `email_not_verified`, `no_account`, `locked_out`, `no_email`, `failed`). `GET /api/v1/accounts/sso` says whether to show the button.

To try it locally, `docker compose up --build` also starts [Dex](docs/dependencies/dex.md), a small provider for development only. Open http://localhost:8080/api/v1/accounts/sso/login?returnUrl=%2Frides and sign in with `rider@sso.test` / `password`. The new account waits for approval, so approve it as the admin first (see above), then sign in again. Use Chrome or Firefox: they send `dex.localhost` to your own machine.

## The Flutter app

Code is in [app/](app/README.md). Its API client is generated: after changing an endpoint run `tools/generate-api-client.sh` (needs the .NET SDK, plus Docker or `OPENAPI_GENERATOR_JAR`) and commit the result. Checks: `cd app && dart format --set-exit-if-changed lib test && flutter analyze && flutter test`. The web build bundles its own rendering engine instead of fetching it from Google's CDN, so it works offline. One known gap: Flutter's default Roboto font is still fetched from Google's font host on first load; bundling it is a follow-up.

## Documents

- [Development environment](docs/development.md)
- [Architecture](docs/architecture.md)
- [v1 scope and architecture](docs/design/v1-scope-and-architecture.md)
- [Product values and principles](docs/design/values.md)
- [v2 ideas: inter-club social layer](docs/design/v2.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [AGENTS.md](AGENTS.md) first: it holds the rules for code, architecture and dependencies. Claude Code reads the same file through `CLAUDE.md`.
