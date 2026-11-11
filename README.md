# Velomine

Cycling-only training platform for clubs and teams. Cloud is the default: one shared deployment and database for many clubs. Self-hosting runs the same image and schema for one club. No feature paywall; every member owns their data. Self-hosting is free for riders and clubs; an optional supporter licence funds the project and unlocks nothing.

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

### Settings you can change

Set them in a file named `.env` next to `docker-compose.yml` (for example `VELOMINE_PORT=9090`), or as environment variables. Infrastructure environment variables are upper case, with `__` for nested settings (`VELOMINE__SMTP__HOST`); the application's internal configuration keys keep their .NET spelling (`Velomine:Smtp:Host`).

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE_PORT` | `8080` | The port of the app. If you change it, also change the port in the redirect address in `deploy/dex/config.yaml`, or the single sign-on test breaks, and set `VELOMINE__PUBLICURL` (used by the compose stack) to the same address. |
| `POSTGRES_PASSWORD` | `velomine-dev` | The database password. Set it before the first start; the database keeps the old one afterwards. |
| `VELOMINE__ADMIN__EMAIL`, `VELOMINE__ADMIN__PASSWORD` | `admin@velomine.local`, `Velomine-dev-1` | The first admin. Only used while the server has no admin. |
| `VELOMINE__PUBLICURL` | `http://localhost:8080` | The address members open, used in password reset emails. Set it to the club's public address (for example `https://club.example`); the incoming Host header is never used. |
| `VELOMINE__MAP__TILEURL`, `VELOMINE__MAP__ATTRIBUTION` | OpenStreetMap | Maps are always on. Set these (under `environment:` of the `server` service) to use a private tile server instead; an empty or unusable address falls back to OpenStreetMap. Read the provider's usage rules first: OpenStreetMap's public servers are for light use only. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `true` | Set to `false` to let new accounts in without approval (add it under `environment:` of the `server` service). An admin can also change this, and sign-up on or off, in the app (*Admin*, *Settings*); a saved value overrides the environment. |
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
