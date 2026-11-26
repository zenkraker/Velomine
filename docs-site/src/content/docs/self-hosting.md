---
title: Self-hosting
description: Run Velomine on a server for your club.
---

Self-hosting is free, with every feature and no member limit. Everything runs with Docker: the server, the web app and PostgreSQL. A self-hosted server serves only the app; the presentation site at velomine.eu is published separately.

A server runs the same `docker-compose.yml` as your computer, from the images CI publishes instead of a build, behind HTTPS.

1. Clone the repository on the server, or copy `docker-compose.yml` there.
2. Copy `.env.example` to `.env` next to it.
3. Set, **before the first start**:
   - `POSTGRES_PASSWORD`: the database keeps its first password afterwards.
   - `VELOMINE__PUBLICURL`: the public address members open, for example `https://club.example`. It appears in password reset emails and calendar feeds.
   - `VELOMINE__ADMIN__EMAIL` and `VELOMINE__ADMIN__PASSWORD`: the first admin (10 characters or more, with an upper-case letter, a lower-case letter and a digit).
   - `VELOMINE_VERSION`: the release to run. Never `latest`.
4. Start it: `docker compose pull && docker compose up -d --wait`. `--wait` fails unless the server and the web app answer.
5. Put your own HTTPS in front of the web container's port (`VELOMINE_PORT`, default 8080). Do not expose that port to the internet directly: it is plain HTTP.

The defaults are for trying it on your own machine only. Set the passwords and the public address before anyone else can reach it.

To upgrade, roll back or back up, see [Backups and upgrades](/docs/backups-and-upgrades/). To send email, see [Email](/docs/email/).

## New members

By default a new rider signs up and starts at once. To approve each one yourself, turn on `VELOMINE__ACCOUNTS__REQUIREADMINAPPROVAL` (or *Admin, Settings* in the app). Admins are then notified in the app, and by email when SMTP is set, and the new account cannot sign in until an admin accepts it.

A self-hosted server never sends a verification email to the person who signed up.

## Try it from source

The [quick start](/docs/quick-start/) runs the published images. This builds the whole stack from source with one command: the server, the web app and PostgreSQL. You do not need .NET, Flutter or PostgreSQL installed.

| Install | Why | Notes |
|---------|-----|-------|
| **Docker** with Compose 2.24 or newer | Builds and runs everything | Windows and macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (on Windows with the WSL 2 backend). Linux: Docker Engine plus the Compose plugin. The command must be `docker compose` (with a space). |
| **Git** | To get the code | Any recent version. |
| **Chrome, Edge or Firefox** | To open the web app | Safari is untested. |

```sh
git clone https://github.com/zenkraker/Velomine.git
cd Velomine
docker compose up --build
```

The first run takes roughly 5 to 10 minutes; later starts take seconds. It is ready when the log shows `Now listening on: http://0.0.0.0:8080`. Open **http://localhost:8080** and sign in as `admin@velomine.local` with the password `Velomine-dev-1`.

Stop it with Ctrl+C. `docker compose down` removes the containers and keeps your data; `docker compose down -v` also deletes the data (database, uploaded files and keys), for a fresh start.

**Trying single sign-on.** `compose.development.yaml` adds Dex, a small test sign-in provider:

```sh
docker compose -f docker-compose.yml -f compose.development.yaml up --build
```

Sign in with *Dex (local test)* as `rider@sso.test` / `password`. It also needs port 5556, and Chrome, Edge or Firefox, which send `dex.localhost` to your own machine. Dex is for trying it out only; never run it on a shared server.

## If something goes wrong

| Problem | What to do |
|---------|-----------|
| `port is already allocated` | Something else uses 8080 (or 5556, with Dex). Stop it, or set `VELOMINE_PORT`. |
| The build fails while downloading | Run it again; it keeps what it already downloaded. Check your internet or proxy settings. |
| The *Continue with Dex* page cannot be found | Use Chrome, Edge or Firefox. They resolve `dex.localhost` themselves; some other browsers and some tools do not. |
| The sign-in provider says the redirect address is wrong | You changed `VELOMINE_PORT` without editing `deploy/dex/config.yaml`. |
| You still see the old app after pulling new code | Run `docker compose up --build` again. |
| The web container is unhealthy, or every page answers 502 | The server is not running. `docker compose logs server` says why; `Could not create the admin: Passwords must ...` means `VELOMINE__ADMIN__PASSWORD` breaks the rules above. |
| You forgot the admin password | The setting only applies while no admin exists. Run `docker compose down -v` to start over (this deletes the data). |
| Something else | `docker compose logs -f server` shows the server's log; add `web`, `postgres` or `dex` for those. |
