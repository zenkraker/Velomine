# Velomine

Cycling-only training platform for clubs and teams. Cloud is the default: one shared deployment and database for many clubs. Self-hosting runs the same image and schema for one club. No feature paywall; every member owns their data. Self-hosting is free for riders and clubs; an optional supporter licence funds the project and unlocks nothing.

## Licence

Velomine is licensed under the [GNU AGPL-3.0](LICENSE). The Velomine name and marks are reserved: a fork may not present itself as Velomine.

## Run it on your computer

This starts the self-host stack with one command: the server, the web app and PostgreSQL, built from source. You do not need .NET, Flutter or PostgreSQL installed.

### What to install

| Install | Why | Notes |
|---------|-----|-------|
| **Docker** with Compose 2.24 or newer | Builds and runs everything | Windows and macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (on Windows with the WSL 2 backend). Linux: Docker Engine plus the Compose plugin. The command must work as `docker compose` (with a space), not the old `docker-compose`. |
| **Git** | To get the code | Any recent version. |
| **Chrome, Edge or Firefox** | To open the web app | Safari is untested. |

Also needed:
- **About 8 GB of free disk and 4 GB of RAM for Docker.** The first build downloads the .NET SDK, the Flutter SDK and PostgreSQL, and compiles the web app inside Docker.
- **Internet access for the first build.** It reaches `mcr.microsoft.com`, `ghcr.io`, `docker.io`, `nuget.org`, `pub.dev` and `storage.googleapis.com` (the Flutter SDK). Behind a company proxy, set that up in Docker first.
- **A free port 8080.**
- **Apple Silicon Macs (arm64):** Flutter only ships a Linux x64 build, so the web build step runs emulated and takes longer. This has not been tried on an arm64 machine; if the build fails there, please open an issue with the output.

### Start it

```
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
docker compose up --build
```

The first run takes roughly 5 to 10 minutes (later starts take seconds). It is ready when the log shows `Now listening on: http://0.0.0.0:8080`. Then open **http://localhost:8080** — the presentation site. Press *Sign in* to open the web app, and sign in as `admin@velomine.local` with the password `Velomine-dev-1`.

Stop it with Ctrl+C. `docker compose down` removes the containers and keeps your data; `docker compose down -v` also deletes the data (database, uploaded files and keys), for a fresh start.

**Trying single sign-on.** `compose.development.yaml` adds Dex, a small test sign-in provider:

```
docker compose -f docker-compose.yml -f compose.development.yaml up --build
```

Sign in with *Dex (local test)* as `rider@sso.test` / `password`. It also needs port 5556, and Chrome, Edge or Firefox, which send `dex.localhost` to your own machine. Dex is for trying it out only; never run it on a shared server.

## Run it on a server

A server runs the same `docker-compose.yml`, from the images CI publishes instead of a build, behind HTTPS.

1. Put `docker-compose.yml` (and `compose.demo.yaml`, if you want Traefik) in a folder on the server, or clone the repository there.
2. Copy `.env.example` to `.env` next to them and set at least `VELOMINE_VERSION`, `POSTGRES_PASSWORD`, `VELOMINE__PUBLICURL` and the first admin. See *Settings you can change*.
3. Put HTTPS in front. Either:
   - **Traefik from `compose.demo.yaml`**, which gets Let's Encrypt certificates itself: point the domain's DNS at the server, open ports 80 and 443, and set `COMPOSE_FILE=docker-compose.yml:compose.demo.yaml`, `VELOMINE_DOMAIN` and `VELOMINE_ACME_EMAIL` in `.env`. The public demo runs exactly this.
   - **Your own reverse proxy**, forwarding to the web container's port (`VELOMINE_PORT`, default 8080). Do not expose that port to the internet directly: it is plain HTTP.
4. Start it: `docker compose pull && docker compose up -d --wait`. To upgrade or roll back, change `VELOMINE_VERSION` and run the same command. `--wait` fails unless the server and the web app answer.

**Backups:** the database (`docker compose exec postgres pg_dump -Fc -U velomine velomine > velomine.dump`) and the `velomine-files` and `velomine-keys` volumes, together. Without the keys, every member is signed out and old links stop working.

### Settings you can change

Set them in a file named `.env` next to `docker-compose.yml`. [`.env.example`](.env.example) lists every one with its default; copy it to `.env` and change what you need. Every variable in `.env` reaches the server. Names are upper case, with `__` for a nested setting (`VELOMINE__SMTP__HOST` is the server's `Velomine:Smtp:Host`).

**Compose**

| Setting | Default | What it does |
|---------|---------|--------------|
| `COMPOSE_FILE` | `docker-compose.yml` | The compose files plain `docker compose` commands use. `docker-compose.yml:compose.demo.yaml` adds Traefik. |
| `VELOMINE_VERSION` | `dev` | The published images to run, for example `0.1.0`. Unset, `docker compose up --build` builds them from source. |
| `VELOMINE_PORT` | `8080` | The port of the app on this machine. Not published with `compose.demo.yaml`. With Dex, also change the redirect address in `deploy/dex/config.yaml`. Set `VELOMINE__PUBLICURL` to match. |
| `VELOMINE_DOMAIN`, `VELOMINE_ACME_EMAIL` | none | `compose.demo.yaml` only, and required there: the host name members open, and Let's Encrypt's contact for expiry notices. |
| `POSTGRES_PASSWORD` | `velomine-dev` | The database password. Set it before the first start; the database keeps the old one afterwards. |
| `CONNECTIONSTRINGS__VELOMINE` | the `postgres` container | An existing PostgreSQL server instead, for example `Host=db.example;Database=velomine;Username=velomine;Password=...`. |

**Server**

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE__PUBLICURL` | `http://localhost:8080` | The address members open, used in password reset emails and each member's calendar feed address. Set it to the public address, for example `https://club.example`; the incoming Host header is never used. |
| `VELOMINE__ADMIN__EMAIL`, `VELOMINE__ADMIN__PASSWORD` | `admin@velomine.local`, `Velomine-dev-1` | The first admin. Only used while the server has no admin. |
| `VELOMINE__ACCOUNTS__SIGNUPENABLED` | `true` | Whether new people can create an account. |
| `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` | `true` | New accounts wait for an admin to approve them. |
| `VELOMINE__ACCOUNTS__CLUBCREATIONENABLED` | `false` | Lets a rider without a club start one. Off, only the operator creates clubs. |
| `VELOMINE__BACKGROUND__ENABLED` | `true` | Ride processing, imports, email, catalogue sync and the first-admin setup. With several server instances of one deployment, keep it on exactly one. |
| `VELOMINE__IMPORTS__MAXARCHIVEMB` | `1024` | The largest Strava export accepted, in MB. A large import needs free disk for the archive and one copy of every activity it brings in. |
| `VELOMINE__RATELIMITS__ANONYMOUSPERMINUTE` | `60` | Requests a minute from one address to sign-in, sign-up, two-factor, password reset and the phone's single sign-on. |
| `VELOMINE__RATELIMITS__UPLOADSPERHOUR` | `600` | The sustained upload rate for one member, in ride files an hour. A whole club behind one address does not share this budget. |
| `VELOMINE__RATELIMITS__UPLOADBURST` | `1000` | How many ride files one member may send at once, for example a whole bike computer folder. |
| `VELOMINE__RATELIMITS__IMPORTSPERDAY` | `10` | How many Strava exports one member may import in a day. |
| `VELOMINE__RATELIMITS__CLUBCREATIONSPERDAY` | `5` | How many clubs one member may start in a day. |
| `VELOMINE__MAP__TILEURL`, `VELOMINE__MAP__ATTRIBUTION` | OpenStreetMap | Maps are always on. Set these to use another tile server; an empty or unusable address falls back to OpenStreetMap. OpenStreetMap's public servers are for light use only: read their rules first. |
| `VELOMINE__SUPPORTER__PUBLICKEY` | empty | The issuer's ECDSA P-256 public key, base64 of the SPKI DER form (`tools/supporter-key.cs gen` prints it). The optional supporter licence is off until it is set, and the server works exactly the same. A licence unlocks no feature. |

The sign-up, approval and club creation switches can also be changed by an admin in the app (*Admin*, *Settings*); a value saved there wins over the environment.

**Email** — on when `HOST` and `FROM` are both set. **Environment only, by design:** the password is never stored in the database or shown in the app. The admin Settings page shows the email setup read-only, with a *Send a test email* button. Without email, password reset answers that it is not available and an admin can make a one-time reset link.

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE__SMTP__HOST`, `VELOMINE__SMTP__FROM` | empty | The SMTP server and the sender, for example `Velomine <velomine@club.example>`. |
| `VELOMINE__SMTP__PORT`, `VELOMINE__SMTP__SECURITY` | `587`, `starttls` | `Security` is `starttls` (port 587), `ssl` (port 465) or `none` (a local relay only). |
| `VELOMINE__SMTP__USER`, `VELOMINE__SMTP__PASSWORD` | empty | The SMTP login, if the server needs one. |

**Single sign-on** — any OpenID Connect provider; on when `AUTHORITY` is set. Environment only, like email. In the provider, register `https://your-club-host/signin-oidc` for the web client and `com.velomine.app:/sso-callback` for the phone.

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE__SSO__AUTHORITY` | empty | The provider's issuer address. |
| `VELOMINE__SSO__CLIENTID`, `VELOMINE__SSO__CLIENTSECRET` | empty | The web client. The secret only if the provider requires one. |
| `VELOMINE__SSO__APPCLIENTID` | empty | The phone's public client (PKCE, no secret). Unset, the phone app has no single sign-on. |
| `VELOMINE__SSO__DISPLAYNAME` | `Single sign-on` | The text of the sign-in button. |
| `VELOMINE__SSO__AUTOCREATEUSERS` | `true` | `false` limits single sign-on to people who already have an account. |
| `VELOMINE__SSO__APPSCOPES__0`, `__1`, … | `openid`, `profile`, `email` | The scopes the phone asks for. Rarely needed. |
| `VELOMINE__SSO__ALLOWINSECUREHTTP` | `false` | Allows an `http://` provider. Development only. |

**Shared parts catalogue** — unset, the server uses the parts list it ships with and sends nothing.

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE__CATALOGUE__URL` | empty | The publisher's full parts list, mirrored every `SYNCMINUTES`. |
| `VELOMINE__CATALOGUE__SYNCMINUTES` | `60` | How often to fetch it, 5 to 1440. |
| `VELOMINE__CATALOGUE__CONTRIBUTEURL`, `VELOMINE__CATALOGUE__CONTRIBUTIONKEY` | empty | Where parts members add are sent, and the key the publisher issued (a secret). Nothing is sent unless both are set; a contribution carries no member, bike, club or address. |
| `VELOMINE__CATALOGUE__CONTRIBUTEMINUTES` | `15` | How often to send waiting contributions, 1 to 1440. |

**Telemetry** — off by default, and a self-hosted server sends nothing. It is vendor-neutral: traces, metrics and logs go over OpenTelemetry's OTLP to any backend, and error reports go to the DSN of any compatible error-tracking service, such as GlitchTip or Bugsink. Each destination is optional, and nothing is sent unless `ENABLED` is `true`. Telemetry carries no member data, and members' apps send data only after they opt in.

| Setting | Default | What it does |
|---------|---------|--------------|
| `VELOMINE__TELEMETRY__ENABLED` | `false` | The switch. |
| `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS`, `OTEL_EXPORTER_OTLP_PROTOCOL` | empty, empty, `grpc` | OpenTelemetry's standard variables: where traces, metrics and logs go, the headers the backend needs (usually its key), and `http/protobuf` or `grpc`. Your backend's OTLP settings give the values. The other standard `OTEL_*` variables work too. |
| `VELOMINE__TELEMETRY__ERRORS__DSN` | empty | Where the server's error reports go: a DSN from GlitchTip, Bugsink or another compatible error-tracking service. |
| `VELOMINE__TELEMETRY__APP__DSN` | the server's DSN | Where opted-in apps send crash reports. |
| `VELOMINE__TELEMETRY__ENVIRONMENT` | `Production` | The deployment name on every signal, for example `demo`. |
| `VELOMINE__TELEMETRY__TRACESAMPLERATIO` | `0.05` | The share of traces sent, 0 to 1. Errors are always reported. |

**Logs**: `Serilog__MinimumLevel__Default` (default `Information`) sets how much the server logs. Logs never contain ride or health data, names, email or IP addresses.

The defaults are for trying it out on your own machine only. Do not expose them to the internet: set the passwords and the public address first.

### If something goes wrong

| Problem | What to do |
|---------|-----------|
| `port is already allocated` | Something else uses 8080 (or 5556, with Dex). Stop it, or set `VELOMINE_PORT` (see above). |
| The build fails while downloading | Run it again; it keeps what it already downloaded. Check your internet or proxy settings. |
| The *Continue with Dex* page cannot be found | Use Chrome, Edge or Firefox. They resolve `dex.localhost` themselves; some other browsers and some tools do not. |
| The sign-in provider says the redirect address is wrong | You changed `VELOMINE_PORT` without editing `deploy/dex/config.yaml`. |
| `required variable VELOMINE_DOMAIN is missing a value` | You use `compose.demo.yaml`: set `VELOMINE_DOMAIN` and `VELOMINE_ACME_EMAIL` in `.env`. |
| You still see the old app after pulling new code | Run `docker compose up --build` again. |
| You forgot the admin password | The setting only applies while no admin exists. Run `docker compose down -v` to start over (this deletes the data). |
| Something else | `docker compose logs -f server` shows the server's log; add `web`, `postgres` or `dex` for those. |

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
