# Velomine

Cycling-only training platform for clubs and teams. Cloud is the default: one shared deployment and database for many clubs. Self-hosting runs the same image and schema for one club. No feature paywall; every member owns their data. Self-hosting is free for riders and clubs; an optional supporter licence funds the project and unlocks nothing.

## Status

Early development. The single-database model below is what runs today, locally and in self-host mode.

**Works today**

- **Accounts:** sign-up with admin approval, password sign-in (cookie on the web, bearer token on the phone), roles club admin, member and coach, password reset by email or by a one-time link an admin makes, two-factor sign-in with an authenticator app and recovery codes, and a device list with "log out other devices".
- **Single sign-on** with any OpenID Connect provider, on the web and on the phone (public client with PKCE).
- **Rides:** FIT, GPX and TCX upload (also gzipped), read in the background into distance, moving time, climbing, speed, power, normalized power, heart rate and cadence. A route map, a chart per signal, laps, heart-rate and power zones, intensity factor, TSS and TRIMP. Four dimensions (surface, e-bike, indoor/virtual, commute), editable and filterable.
- **Bikes:** wheel circumference, a default bike, a bike of the matching kind for each new ride, parts with wear by distance, hours or months, a shared parts catalogue and build templates.
- **Progress:** weekly, monthly and yearly totals, goals, a training dashboard (fitness, fatigue, form), a power curve with FTP and VO2max estimates, readiness, and the daily wellbeing check-in with RPE and notes per ride.
- **Clubs and coaches:** a rider can ride alone or join a club, find nearby clubs that opted in and ask to join. A member shares rides, training, routes or wellbeing with the club's coaches, and sees a log of who looked. Coaches never see notes.
- **Privacy:** privacy zones, start and end trimming and per-stream switches on everything a non-owner sees.
- **Notifications** in the app and by email (with an SMTP server): rides read, failed or duplicated, parts nearly worn, accounts waiting for approval.
- **Your data:** download everything as a ZIP with every original ride file, or delete the account with everything in it.
- **Admin:** accounts (roles, lock, delete, reset password or second factor), sign-up settings, a server overview and a test email.
- **Phone (Android):** records GPS rides with the screen off, a paired Bluetooth heart-rate strap, auto-pause, ride type and e-bike switch written into the FIT file, and uploads with retries, also while the app is closed.
- **Languages:** English and Italian, following the account to every device.
- **Presentation site** at `/` (Home, Status, Pricing, Demo, Contact); the web app opens from *Sign in*.

**Known gaps**

- Row-level security on the club tables is not built yet; club isolation relies on query filters and tests.
- Android allows cleartext HTTP everywhere so a self-hosted server on a LAN can use it; the cloud build should forbid it.
- The iOS recorder and phone single sign-on on iOS have not been run yet.
- The same ride exported by two different apps is not detected as a duplicate.
- There is no CI workflow right now: the demo pipeline waits in `to-move-out/` for the ops repository.
- Server-rendered email is English only.

**Roadmap**

- *Launch:* ride titles and descriptions, search and a date filter on the ride list, then Strava export import with cross-app duplicate detection; self-serve sign-up and payment (solo trial, club creation, the member limit of each club band); "Share to Velomine" for ride files on the phone, drag-and-drop of a bike computer's folder on the web and USB import on Android; the view log shown on each ride; the club ride calendar (date, meeting point, route, sign-up, calendar feed) with a club route library that members add routes to; maintenance reminders and a service log for bikes. On the site: a plain comparison of what Strava charges for against what is included here, and a public pledge that no feature will ever move behind a payment. Before opening to paying clubs: row-level security on club tables, a cloud Android build that forbids cleartext HTTP, Italian emails, re-reading all rides after a parser update, the optional supporter key and badge for self-hosted servers.
- *After launch:* speed, cadence and power sensors and the wheel-speed source; coach comments, then the opt-in club space (ride feed, reactions, comments between members, always under each member's own privacy settings), with "rode with" detection for clubmates on the same ride; a club's calendar and activity level shown to riders looking for a club, never its members' rides; push notifications on the phone; ratings, notes and suggested variants on club routes; a shareable ride card and share links with server-rendered pages; photos, ride thumbnails and reverse geocoding; cost per km for each bike; the Italian presentation site; an audit log of sign-ins and admin actions; outbound address checks for admin-entered URLs.
- *Later:* the iOS recorder; a member's own history on repeated routes and climbs, with opt-in club comparison; a year review; scoped API keys; FIT export of any ride.
- *Only if many riders ask:* reading rides (never health logs) from Health Connect and Apple Health.
- *Not planned for now:* vendor cloud connectors (Garmin, Wahoo) and direct Bluetooth transfer from bike computers; a desktop USB upload tool; audio announcements; live tracking; cycle tracking; the inter-club layer ([v2](docs/design/v2.md)).

**Open questions**

- Weight as a single profile field: W/kg, VO2max and calories need it; confirm it stays one field.
- Wellbeing and cycle data are health data under GDPR. Consent screens, export and deletion are built in; the legal side still needs checking with someone qualified.

## Licence

Velomine is licensed under the [GNU AGPL-3.0](LICENSE). The Velomine name and marks are reserved: a fork may not present itself as Velomine.

## Run it on your computer

This starts the self-host mode with one command: the server, the web app, PostgreSQL, and a small test sign-in provider for trying single sign-on. You do not need .NET, Flutter or PostgreSQL installed.

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
- **Apple Silicon Macs (arm64):** Flutter only ships a Linux x64 build, so the web build step runs emulated and takes longer. This has not been tried on an arm64 machine; if the build fails there, please open an issue with the output.

### Start it

```
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
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
15. **Turn on two-factor sign-in:** open *Profile*, then *Two-factor sign-in*, press *Set up an authenticator*, and type the key into any authenticator app (there is no QR code, by design). Enter the password and the 6-digit code to turn it on, then save the recovery codes; they are shown once. The next sign-in asks for a code after the password. Other devices are signed out when you turn it on; *Turn off* needs the password again.
16. **See and end your sessions:** open *Profile*, then *Devices and sessions*. Every signed-in phone and browser is listed with the last time it was used, the current one is marked, and each other device can be signed out. *Log out other devices* keeps this one. Lost a phone and the recovery codes? A club admin can clear the second factor from *Admin*, *Accounts*; the member signs in with the password and sets it up again.

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
| `VELOMINE__SSO__AUTHORITY`, `VELOMINE__SSO__CLIENTID`, `VELOMINE__SSO__CLIENTSECRET` | empty | Single sign-on is on when all three are set. In the provider, allow the redirect address `https://your-club-host/signin-oidc`. `VELOMINE__SSO__DISPLAYNAME` is the button text; `VELOMINE__SSO__AUTOCREATEUSERS=false` limits sign-in to existing accounts. |
| `ASPNETCORE_FORWARDEDHEADERS_ENABLED` | `false` | Set to `true` behind a reverse proxy that ends TLS, so Velomine builds `https` addresses. |
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

**Recommended: the Nix dev environment.** `flake.nix` provides every tool below at pinned versions (the Flutter release matches the `Dockerfile`), plus the Android SDK and emulator, Node for ponytail and CodeGraph, without installing them into your system. With direnv the tools load when you enter the folder, and `just` runs the everyday commands (`just up`, `just logs`, `just emu`, `just phone`, `just check`). The server always runs in Docker, as in the steps above. [docs/development.md](docs/development.md) explains how it works and walks through the one-time setup.

**Without Nix**, install these yourself:

| Install | For |
|---------|-----|
| **.NET SDK 10** | Building and testing the server (the tests also need Docker; they start their own PostgreSQL and Dex). |
| **Flutter 3.47.9** (comes with Dart 3.13.7) | The app. Run `flutter doctor` to see what else your target needs (Android Studio for Android, Xcode for iOS). |
| **just** | `just check` runs every check before a commit; `just --list` shows the rest. |
| **Java 11 or newer, or Docker** | Regenerating the API client with `tools/generate-api-client.sh`. |
| **Claude Code or OpenCode, with the ponytail plugin, plus CodeGraph** | Required for working on this repository; see [AGENTS.md](AGENTS.md). |

## Documents

- [Development environment](docs/development.md)
- [Architecture](docs/architecture.md)
- [Code, API and app rules](AGENTS.md)
- [Product values and scope](docs/design/values.md)
- [v2 ideas: inter-club social layer](docs/design/v2.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [AGENTS.md](AGENTS.md) first: it holds the rules for code, the API, the app and dependencies, and the approved libraries. Run `just check` before every commit. Claude Code reads the same file through `CLAUDE.md`.
