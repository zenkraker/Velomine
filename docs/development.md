# Development environment

This guide sets up a machine for **working on** Velomine: building and testing the server, running the Flutter app on the web and on a phone, and regenerating the API client. To only **run** Velomine you do not need any of this: `docker compose up --build` (see the [README](../README.md)) is enough.

The toolchain is a dev container in `.devcontainer/`. It holds the editor, the agents and every SDK at pinned versions, and nothing is installed into your machine but Docker and VS Code. There is one way in: no shell setup, no host packages, no second environment to keep in step.

## How it works

**One container holds the toolchain.** `.devcontainer/Dockerfile` builds it, `devcontainer.json` adds devcontainer features (.NET 10, Node 24, Docker) and the editor extensions, and `devcontainer-lock.json` pins each feature by digest. [VS Code's Dev Containers extension](https://code.visualstudio.com/docs/devcontainers/containers) builds the image and attaches the editor to it, so the terminal, the agents, the Dart/C# language servers and the debuggers all run inside.

**Docker runs inside the container.** The `docker-in-docker` feature starts its own daemon there, so `just up` and the tests' Testcontainers start containers in it. Your host's Docker socket is never mounted; the container is `--privileged` for its own daemon, and that privilege stays inside it. Ports 8080 (the stack) and 5556 (Dex) are forwarded to your machine.

**State stays off your machine.** Build caches (NuGet, pub, Gradle, npm, the Android SDK's home) go to `.dev/` in the repository, which is git-ignored and safe to delete. Agent logins and settings go to one Docker volume, `velomine-state`, mounted at `~/.state`. Without the volume the container is disposable.

**The server is never run from a shell.** `docker-compose.yml` is the stack, `compose.development.yaml` adds Dex, and `just up` runs both. That is the same file a self-hoster uses; nothing in the repository starts the server as a host process.

### What lives where

| Place | What | Why there |
|-------|------|-----------|
| Your machine (Docker, VS Code) | The container runtime, the editor, a Chromium-based browser | Things a container cannot provide |
| `.devcontainer/` | The toolchain: every tool and version the project needs | Pinned and reproducible; the only place versions are set |
| `.dev/` in the repository | Build caches, the Android home | Machine-local and writable; safe to delete |
| The `velomine-state` volume | Logins, settings, sessions and caches of the agents and the editor | Survives a rebuild; `docker volume rm velomine-state` removes all of it |
| Docker | PostgreSQL, Dex, the server and the web image | The same containers as `just up`; see [the compose file](../docker-compose.yml) and [the development overlay](../compose.development.yaml) |

## What is inside

| Tool | Version | Where |
|------|---------|-------|
| .NET SDK | 10.0 | devcontainer feature `dotnet` |
| Node.js | 24 (through nvm) | devcontainer feature `node` |
| Docker, Docker Compose | Docker's current release | devcontainer feature `docker-in-docker` |
| Java | JDK 17 | Debian 12's apt |
| Flutter | 3.50.0 (Dart 3.14.0) | `/opt/flutter`, the official release with the **same version and checksum as `app/Dockerfile`** |
| Android SDK | platforms 35 and 36, build tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1, platform-tools | `/opt/android-sdk`, the versions Flutter 3.50's Gradle plugin asks for |
| `just` | 1.59.0 | `/usr/local/bin` |
| CodeGraph | 1.6.4 | `/opt/codegraph` |
| Sentry CLI | 3.8.2 | `/usr/local/bin`, for releases and debug symbols |
| Scaleway CLI | 2.67.0 | `/usr/local/bin` |
| GitHub CLI (`gh`) | 2.105.0 | `/usr/local/bin`, for releases and tags |
| Claude Code | 2.1.329 | npm, in the volume; the agents' CLI |
| Sentry MCP | 0.49.0 | npm, in the volume; the local server Pi starts |

The image is Debian 12, the last Debian whose apt has JDK 17, which Gradle 9, the Android Gradle Plugin 9, CI and the OpenAPI generator all need. **Not in the container:** the Android emulator and its system images (no hardware acceleration inside a container, so use a phone with `just phone`). A browser for a person to click in is not there either: use `just up`, or `flutter run -d web-server` and open the forwarded port on your machine. **In the container:** `chrome-headless-shell` (Chrome for Testing, pinned in the `Dockerfile`), which `dart run tools/screenshots.dart` drives for the screenshot check — it takes pictures, it is not a browser to work in. iOS builds need macOS with Xcode.

## Set up

### 1. Install Docker and VS Code

Docker Engine with Compose, and [VS Code](https://code.visualstudio.com/) from Microsoft's build, with the Dev Containers extension (`ms-vscode-remote.remote-containers`). On Arch and CachyOS that is the AUR package `visual-studio-code-bin` (`paru -S visual-studio-code-bin`; read its PKGBUILD first): the `code` package is the open-source build, and Microsoft's extension refuses to run in it.

### 2. Open the repository in the container

Open the folder, then choose *Dev Containers: Reopen in Container*. The first start builds the image and runs `post-create.sh`: it downloads several GB, so it takes a while. Later starts reuse the image and take seconds.

### 3. Project setup

```
just setup
codegraph telemetry off
codegraph init
```

- `just setup` restores the .NET tools and fetches the Flutter packages (`flutter pub get`).
- `codegraph telemetry off` is a one-time setting per machine. `codegraph init` builds the code index in `.codegraph/`, which is git-ignored; the agents' CodeGraph MCP server reads it.

### 4. Sign in once

Inside the container, once. Each login stays in the volume, so it survives a rebuild:

- **Claude Code:** run `claude` in the terminal and sign in. Pi's `pi-claude-tether` uses this login.
- **Pendant (Pi):** sign in to your providers from its sidebar.
- **Sentry MCP:** `sentry-mcp auth login` (for Pi's local server), and `/mcp` in Claude Code for the hosted one.
- **Scaleway MCP:** `scw init -p velomine-readonly` with the least-privilege key, never the account key.

### 5. Try it

```
just up              # build and start PostgreSQL, Dex, the server and the web image
```

Open http://localhost:8080 and sign in as `admin@velomine.local` / `Velomine-dev-1`. The server and the web app run only in Docker; the presentation site is not served locally (open `site/index.html` in a browser, but its app links point at the demo). After a change, run `just up` again.

For Android, connect the phone once by USB on the host, run `adb tcpip 5555`, then `just phone <phone-ip>:5555` in the container. Android 11+ can pair with *Wireless debugging* instead.

## Agents

**Claude Code** is installed by `post-create.sh` into the volume, never on the host, and it never updates itself. It reads the project rules through `CLAUDE.md`, the MCP servers from `.mcp.json` and its own settings from `.claude/settings.json`. Non-secret settings for both agents are in `.devcontainer/config/`; `post-create.sh` copies them into the volume and never overwrites a file already there. Never put credentials there (see its `README.md`).

The **ponytail** plugin is mandatory (see [AGENTS.md](../AGENTS.md)). Accept its marketplace and plugin when Claude Code asks; the status line shows `[PONYTAIL NOT INSTALLED]` until it is set up. To install it by hand:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Ponytail keeps changes small (smallest complete change, YAGNI, stdlib first). Its hooks need `node`, which the container has. Useful commands: `/ponytail-review` before a PR, `/ponytail-audit` for the whole repo, `/ponytail-debt` to list `shortcut:` comments.

**CodeGraph** indexes the code into a local symbol graph and gives the agent one MCP tool, `codegraph_explore`, which returns the source of the relevant symbols with their call paths (`codegraph explore "..."` does the same in a shell). `.mcp.json` starts its server and `.claude/settings.json` runs its prompt hook.

**Pi** comes from the [Pendant](https://marketplace.visualstudio.com/items?itemName=cdervis.vscode-pi) extension in `devcontainer.json`, which bundles its own. It reads `AGENTS.md` directly, its packages (ponytail, `pi-claude-tether`, `pi-advisor-flow`) from `.pi/settings.json` and its MCP servers from `.pi/mcp.json`, and it loads the project skills through `pendant.extraSkills`. Its subagent profiles are VS Code settings in `customizations.vscode.settings`.

**The Dart MCP server** is the one bundled with the pinned SDK. Do not install a separate global copy:

```
dart mcp-server --version     # 1.2.2 with Flutter 3.50.0 / Dart 3.14.0
flutter --version
```

Claude Code gets the official Flutter plugin and its skills:

```
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
```

**Project skills.** The skills in `.claude/skills/` (dotnet, flutter, postgres, software-architecture) are loaded into every session of both agents: `CLAUDE.md` imports them for Claude Code, and `pendant.extraSkills` in `.devcontainer/devcontainer.json` lists them for Pi. When you add a skill, add it to both. `AGENTS.md` wins where a skill disagrees with it.

**Sentry MCP** is available in two forms, both read-only (`inspect,triage`). Claude Code uses the hosted server in `.mcp.json` and signs in through `/mcp`. Pi starts the local `@sentry/mcp-server` that `post-create.sh` installs, with the same skills from the `env` of `.pi/mcp.json`. Without an LLM provider the local server's AI-powered search tools are unavailable, but project/DSN discovery and the other tools work. To add `project-management` for a setup task, add it to that `env` and re-authorize; never commit a token.

**Scaleway MCP** is Scaleway's own server, built into the CLI (`scw mcp server serve`). `.mcp.json` and `.pi/mcp.json` start it read-only (`read-only=true`), so only get and list commands exist, limited to the namespaces `instance`, `rdb`, `dns`, `object`, `iam`, `registry` and `vpc`. The flags are in those two files, so there is no wrapper script to keep in step.

It runs under the CLI profile `velomine-readonly`. Create the key for it once:

1. In the Scaleway console, create an IAM application for agents, with a policy scoped to the Velomine project.
2. Give the policy read-only permission sets only: `InstancesReadOnly`, `RelationalDatabasesReadOnly`, `DomainsDNSReadOnly`, `ObjectStorageReadOnly`, `IAMReadOnly`, `ContainerRegistryReadOnly` and `VPCReadOnly`.
3. Generate an API key for the application and store it as a profile: `scw init -p velomine-readonly`.

Never use the account key, and never commit a key. Changes to the infrastructure are made by hand, never through the MCP.

**Two roles on top of the agents.** The project manager turns an idea into stories in `docs/stories/` and keeps
the milestones; the software architect guards `AGENTS.md` and `docs/architecture.md` §10. Both are defined in
`docs/roles/`, and both agents read those same documents, so the roles cannot drift apart: Pi gets them as
project prompt templates (`/pm`, `/architect` in `.pi/prompts/`), Claude Code as project subagents in
`.claude/agents/`. Run `/reload` in Pi after changing a template. `docs/business.md` is the CEO's: the project
manager quotes it and asks, rather than filling it in.

## Telemetry

Telemetry is for the demo only. The local stack never sends any: `compose.development.yaml` forces `VELOMINE__TELEMETRY__ENABLED=false`, even when your `.env` is a copy of the demo's. The demo's settings are in `.env.example` under *Telemetry*. The phone reads the app DSN from `GET /api/v1/server`, and only after a member opts in under **Profile → Privacy**.

Release builds do not upload debug symbols or web source maps yet. When you want readable release stack traces, add the Sentry Dart Plugin and pass `SENTRY_AUTH_TOKEN` as a build secret; it is deliberately not enabled by default because a self-hosted image has no token.

## Daily work

Run `just` on its own to list every command.

| Command | What it does |
|---------|--------------|
| `just up` | Builds the images and starts PostgreSQL, Dex, the server and the web image in Docker on http://localhost:8080, in the background: `docker-compose.yml` plus `compose.development.yaml`. Every `just` recipe that calls `docker compose` uses both files. Run it again after any change. |
| `just logs` | Follows the server's log |
| `just down` / `just nuke` | Stops the containers. `nuke` also deletes the database, the ride files and the Data Protection keys. |
| `just db` | Opens psql on the database inside the postgres container |
| `just phone [ip:port]` | Runs the app on a real phone over Wi-Fi adb, forwarding ports 8080 and 5556 so the app reaches the server and Dex at `localhost`. Turn on *Wireless debugging* on the phone and pair it once (`adb pair`); then `just phone 192.168.1.20:5555` connects and runs, and plain `just phone` uses a phone that is already connected. |
| `just migration Name` | Adds an EF Core migration under `Data/Migrations` |
| `just api-client` | Regenerates the Dart API client after an endpoint change (`tools/generate-api-client.sh`) |
| `just codegen` | Regenerates the Riverpod providers (`build_runner`). Run it after changing a `@riverpod` provider; the generated `.g.dart` files are committed. |
| `just check` | Runs every check before a commit: .NET format check, server tests, Riverpod codegen, Dart format, analyzer, Flutter tests and the Android unit tests |
| `just check-server` | The server half of `just check`: .NET format check and server tests. Enough for a change that touches no file under `app/` |

`just emu` runs the app on an Android emulator and is meant for a machine where one is installed: the dev container has no emulator or system image, so use `just phone` there.

There is one way to run Velomine, in development and for a self-hoster alike: `docker-compose.yml`. Development adds `compose.development.yaml` (Dex) and the demo and dev servers add `compose.hosted.yaml` (behind the shared Traefik in `deploy/traefik/`); nothing runs the server from your shell. Settings go in `.env`; `.env.example` lists every one. `flutter run -d chrome` still works for quick UI work on a machine with a browser, but password sign-in needs the cookie, which only works when the server serves the app, so use `just up` for anything that needs a session.

## Updating tools

Every version is in `.devcontainer/` or, for Flutter, in `app/Dockerfile` too. After changing the image, rebuild the container (*Dev Containers: Rebuild Container*).

- **Flutter:** change `FLUTTER_VERSION` and `FLUTTER_SHA256` in `app/Dockerfile` **and** `.devcontainer/Dockerfile`, in the same commit; `tools/check-versions.sh` fails when they differ, and CI reads the pin from `app/Dockerfile`. Take both values from Flutter's [release list](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json). A new minor version (3.51 rather than 3.50.x) may ask for newer Android SDK or NDK versions; its template names the Gradle, Android Gradle Plugin and Kotlin versions it is tested with (`packages/flutter_tools/lib/src/android/gradle_utils.dart`). Use those in `app/android/` and in the Dockerfile's `sdkmanager` line.
- **.NET, Node, Docker:** change the `version` in the feature list of `devcontainer.json`, rebuild, and commit the `devcontainer-lock.json` the devcontainer CLI updates with it. `dotnet` and `node` name a major (`2`) whose latest the lock pins; `docker-in-docker` names the exact version it was tested at.
- **Release binaries in the image** (`just`, CodeGraph, Sentry CLI, Scaleway CLI, `gh`, the Android command-line tools): change the `ARG` version **and** its `*_SHA256` in `.devcontainer/Dockerfile`. Take the checksum from the release's own `SHA256SUMS` or by downloading the asset once. A stale checksum fails the build, which is the point.
- **Claude Code and the Sentry MCP server:** the versions in `post-create.sh`. Run `bash .devcontainer/post-create.sh` to install them again into the volume.
- **Agent plugins:** for Pi, the pinned versions in `.pi/settings.json` after reading the changelog. Claude Code's plugins (ponytail, the official Flutter plugin) update through `claude plugin update`.
- **VS Code extensions:** `customizations.vscode.extensions` in `devcontainer.json`.

## Troubleshooting

| Problem | What to do |
|---------|-----------|
| The container does not start, or Docker inside it does not | Docker on the host must be running. The container needs to be `--privileged` for its own daemon; `devcontainer.json` sets that. |
| `npm: command not found` in a script | Node comes from the node feature's nvm (`/usr/local/share/nvm`), which only login shells get on `PATH`. Source `nvm.sh` first, as `post-create.sh` does. |
| The build of the container fails at `sha256sum -c` | A version was bumped without its checksum. The message names the file; update the `*_SHA256` next to the `ARG`. |
| `port is already allocated` on 8080 | Another program uses the port. Stop it, or set `VELOMINE_PORT` in `.env`. |
| Single sign-on through Dex fails | Dex only accepts `http://localhost:8080/signin-oidc`: keep `VELOMINE_PORT` at 8080, or change the redirect address in `deploy/dex/config.yaml` too. |
| Gradle wants an SDK component or NDK version that is not installed | Add the exact version it names to the `sdkmanager` line in `.devcontainer/Dockerfile` and rebuild the container. |
| `flutter run -d chrome` finds no browser | The container has no browser. Use `just up`, or `flutter run -d web-server` and open the forwarded port on your machine. |
| The emulator does not start | There is none in the container. Use a phone with `just phone`. |
| Something is stale | `rm -rf .dev` and rebuild the container; caches download again and nothing in git is affected. |
| The agents lost their logins after a rebuild | They live in the `velomine-state` volume, which a rebuild keeps. A `docker volume rm velomine-state` starts over. |

## Removing it

Delete the container and its image from the Dev Containers view, then `docker volume rm velomine-state` and delete `.dev/`. The stack's own data goes with `just nuke`; `docker image prune` removes the images it built.
