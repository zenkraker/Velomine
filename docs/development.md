# Development environment

This guide sets up a machine for **working on** Velomine: building and testing the server, running the Flutter app on the web and on the Android emulator, and regenerating the API client. To only **run** Velomine, you do not need any of this: `docker compose up --build` (see the [README](../README.md)) is enough.

Every development tool comes from one file, `flake.nix`, at exact versions. Nothing is installed into your Linux distribution, and two developers with the same `flake.lock` get the same tools.

## How it works

You only need a few ideas to use this setup.

**Nix is a package manager, not an operating system.** NixOS is a Linux distribution built on Nix, but you don't need it. Nix runs alongside pacman, apt or Homebrew without touching the packages they manage.

**Packages live in `/nix/store`.** Each package has its own folder, named by a hash of exactly how it was built (for example `/nix/store/abc123…-dotnet-sdk-10.0.300`). Versions never overwrite each other. The store is read-only: once a package is there, it never changes. A background service, `nix-daemon`, downloads packages into it. You never talk to the daemon directly.

**`flake.nix` is a recipe; `flake.lock` pins it.** The flake lists the tools the project needs and the environment variables to set. The lock file records the exact revision of [nixpkgs](https://github.com/NixOS/nixpkgs) (the package collection) the tools come from. The flake is committed. Change it to add, remove or update a tool.

**A dev shell is an ordinary shell with a different `PATH`.** Entering the dev shell puts the flake's tools first on `PATH` and sets the variables. You stay on your own machine, with your own files, editor and Docker. It is not a container or a virtual machine. Nothing keeps running, so there is nothing to save or stop: leave the shell and the tools are off your `PATH`. The packages stay in the store, so the next start takes about a second.

**direnv enters the shell for you.** With [direnv](https://direnv.net/), changing into the repository folder loads the dev shell, and leaving the folder unloads it. The `.envrc` file (`use flake`) tells it to. The direnv extension for VS Code does the same for the editor, its terminal and its language servers.

**Caches go to `.dev/`, not to your home folder.** NuGet, pub and Gradle write into their caches while they run, so the caches cannot live in the read-only store. The dev shell redirects them into `.dev/` in the repository, together with the unpacked Flutter SDK and the emulator. `.dev/` is git-ignored. Delete it and all of that is gone. Your lock files (`packages.lock.json`, `pubspec.lock`, `flake.lock`) still pin every version.

### What lives where

| Place | What | Why there |
|-------|------|-----------|
| Your distribution (pacman, apt, …) | Nix, direnv, Docker, VS Code, a Chromium-based browser | Used across all projects, or system services Nix cannot run |
| `flake.nix` (in `/nix/store`) | .NET SDK, Flutter tarball, Android SDK, Java, Node, CodeGraph, OpenCode, VS Code with extensions, just | Versions that matter to this project |
| `.dev/` in the repository | Caches, unpacked Flutter, emulator | Machine-local and writable; safe to delete |
| Docker | PostgreSQL and Dex | The same containers as `docker compose`; see [the compose file](../docker-compose.yml) |

## What the flake provides

| Tool | Version | Why |
|------|---------|-----|
| .NET SDK | 10.0 (from nixpkgs) | Server and tests. EF Core tools come from `dotnet-tools.json`, restored when the shell starts. |
| Flutter | 3.47.9 with Dart 3.13.7 | The official release with the **same version and checksum as the `Dockerfile`**. Not the nixpkgs build, which lags behind (3.47.4 with Dart 3.13.3, too old for `app/pubspec.yaml`). It is unpacked once into `.dev/`, because Flutter writes into its own folder. |
| Android SDK | platform 36, build tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1, emulator, Play Store image (x86_64) | The versions Flutter 3.47's Gradle plugin asks for |
| Java | JDK 17 | Gradle 9 and the Android Gradle Plugin 9 need Java 17 or newer. It also runs the OpenAPI generator JAR. |
| Claude Code | 2.1.322 | AI coding agent, pinned ahead of nixpkgs from Anthropic's release manifest (see *Updating tools*). It is the only install: no native installer, npm package or VS Code Marketplace extension on the host, and it never updates itself. |
| Node.js | from nixpkgs | Ponytail's Claude Code hooks (see [AGENTS.md](../AGENTS.md)) |
| CodeGraph | from nixpkgs | Required by AGENTS.md, so there's no `curl … \| sh` install |
| OpenCode | from nixpkgs | AI coding agent, an alternative to Claude Code |
| VS Code | 1.144 with the project's extensions | `nix run .#vscode`: Dart/Flutter, Nix IDE, direnv, C# Dev Kit, Claude Code (same version as the CLI) and OpenCode V2. It is the same Microsoft build as `visual-studio-code-bin`. |
| just | from nixpkgs | Runs the commands in the `justfile` |
| nixd | from nixpkgs | Language server for editing `flake.nix` |

Agent plugins are not part of the dev shell: ponytail and the official Flutter plugin (Flutter/Dart skills plus the `dart mcp-server` MCP server) are installed in each agent itself. Step 5 has the details.

The flake targets `x86_64-linux`. iOS builds need macOS with Xcode, which this setup cannot provide.

## Set up (Arch Linux and CachyOS)

These are one-time steps per machine. The commands use fish, the CachyOS default. In bash or zsh, only step 3 changes.

### 1. Install the host packages

```
sudo pacman -S nix direnv docker docker-compose docker-buildx chromium
paru -S visual-studio-code-bin
```

- `nix` is the package manager. `direnv` loads the dev shell when you enter the folder; step 3 adds `nix-direnv`, which caches the shell and keeps its packages from being garbage-collected.
- `docker`, `docker-compose` and `docker-buildx` run PostgreSQL and Dex, the tests' Testcontainers, the full stack, and the OpenAPI generator.
- `chromium` is used by `flutter run -d chrome`. Google Chrome works as well.
- Use **`visual-studio-code-bin`** (Microsoft's build), not `code`. The open-source build cannot install the C# Dev Kit.

### 2. Turn on the services, the flakes feature and your groups

```
sudo systemctl enable --now nix-daemon.socket docker.service
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon.socket
sudo usermod -aG docker,kvm $USER
```

- The first line starts the Nix daemon and Docker now and at every boot.
- The second line turns on the `nix` command and flakes. Both are still labelled experimental, though they're widely used. Without this line you get `experimental Nix feature 'nix-command' is disabled`.
- The `docker` group lets you use Docker without `sudo`. On a development machine this is normal, but note that it is effectively root access.
- The `kvm` group gives the Android emulator hardware acceleration. See *Troubleshooting* if the group is missing.

Log out and back in (or reboot) so the new groups apply. Then check:

```
nix store info     # should print "Store URL: daemon"
groups             # should list docker (and kvm, unless /dev/kvm is open to everyone)
```

Arch's `nix` package does not create a `nix-users` group, and you don't need one: by default, every user may use the daemon.

### 3. Hook direnv into your shell

```
echo 'direnv hook fish | source' >> ~/.config/fish/config.fish
nix profile install nixpkgs#nix-direnv
mkdir -p ~/.config/direnv
echo 'source ~/.nix-profile/share/nix-direnv/direnvrc' >> ~/.config/direnv/direnvrc
```

The first line lets direnv react when you change folders. In bash use `eval "$(direnv hook bash)"` in `~/.bashrc`, and in zsh `eval "$(direnv hook zsh)"` in `~/.zshrc`. `nix-direnv` is not in the Arch repositories, so the second line installs it from nixpkgs. The last two lines make direnv use it, which caches the shell and keeps its packages from being garbage-collected, so entering the folder is instant after the first time. Open a new terminal afterwards.

### 4. Install the VS Code extensions

```
code --install-extension mkhl.direnv
code --install-extension jnoortheen.nix-ide
code --install-extension Dart-Code.flutter
code --install-extension ms-dotnettools.csdevkit
```

- **direnv** (`mkhl.direnv`, maintained under the [direnv organisation](https://github.com/direnv/direnv-vscode)) loads the dev shell into VS Code. Without it, VS Code doesn't find the SDKs unless you start it with `code .` from inside the shell.
- **Nix IDE** gives syntax highlighting and completion for `flake.nix`, using `nixd` from the flake.
- **Flutter** (also installs Dart) and **C# Dev Kit** are the language extensions. The flake sets `DOTNET_ROOT` so the C# Dev Kit finds the SDK.

The flake also builds the same VS Code with those extensions, plus Claude Code and OpenCode V2: run `nix run .#vscode` from the repository. It keeps your normal VS Code settings, and its extensions come from the flake instead of the Marketplace. Use it for Claude Code in VS Code: don't install the Claude Code extension into your host VS Code.

### 5. Set up Claude Code

Claude Code comes from the dev shell; don't install it on the host. Start `claude` from the repository folder with the shell loaded, so it and the ponytail hooks, CodeGraph and `dart mcp-server` all come from the flake. Outside the shell there is no `claude` command. Your login, settings, plugins and history stay in `~/.claude/` and `~/.claude.json`, like any program's settings. If you used the native installer before, remove it from a terminal outside Claude Code (a running native Claude Code puts its own files back): `rm -rf ~/.local/bin/claude ~/.local/share/claude ~/.local/state/claude ~/.local/share/applications/claude-code-url-handler.desktop` and `code --uninstall-extension anthropic.claude-code`. Accept the ponytail marketplace and plugin when it asks (see [AGENTS.md](../AGENTS.md)). The status line shows `[PONYTAIL NOT INSTALLED]` until it is set up. To install it by hand:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Ponytail keeps changes small (smallest complete change, YAGNI, stdlib first). Its hooks need `node`, which the dev shell provides. Useful commands: `/ponytail-review` before a PR, `/ponytail-audit` for the whole repo, `/ponytail-debt` to list `shortcut:` comments.

CodeGraph indexes the code into a local symbol graph and gives the agent one MCP tool, `codegraph_explore`, which returns the source of the relevant symbols with their call paths (`codegraph explore "..."` does the same in a shell). `.mcp.json` starts its server and `.claude/settings.json` runs its prompt hook, so `codegraph` must be on PATH when Claude Code starts: start it from the dev shell. Without Nix, install it with `curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`.

OpenCode reads `AGENTS.md` directly and takes its MCP servers and plugins from `opencode.json`; Claude Code reads the same rules through `CLAUDE.md` and its MCP servers from `.mcp.json`. OpenCode needs no install command for ponytail: the `plugins` entry loads `@dietrichgebert/ponytail` from npm on first start and keeps it active in every session of this repository. Both start the Dart MCP server with `dart mcp-server`, which ships with the pinned Flutter SDK: start the agent from the dev shell (with direnv loaded) so `dart` and `FLUTTER_ROOT` are set. For OpenCode that includes its background service, which spawns MCP servers: after a `direnv reload`, restart it with `opencode service restart` from the repository. The first launch resolves the server package into the pub cache in `.dev/`. Install the official Flutter agent plugin (the Flutter/Dart skills plus that MCP server) in each agent as [Flutter's AI setup](https://docs.flutter.dev/ai/get-started) describes; the dev shell provides the SDK, not the agent's skills.

#### OpenCode desktop

The OpenCode desktop app is optional and is installed on the host, not from the flake. It connects to the background service of the flake's CLI, which gets a fixed port and password once:

```bash
opencode service set port 4096
opencode service set password '<a password of your own>'
```

Both are stored in `~/.config/opencode/service-prod.json`, outside the repository, and survive restarts. Each day, start the service from the repository with the dev shell loaded, so the MCP servers it spawns find `dart`, `sentry-mcp` and `scw-mcp`:

```bash
opencode service start    # http://127.0.0.1:4096
```

In the desktop app, add that address under the server settings with the user `opencode` and your password. The `opencode` command in the dev shell uses the same service, so the terminal and the desktop share sessions. Keep the desktop on the same release as the CLI pinned in `flake.nix`.

#### Agent MCP servers

The Dart MCP server is the one bundled with the pinned SDK. Do not install a separate global copy:

```
dart mcp-server --version     # 1.2.2 with Flutter 3.47.9 / Dart 3.13.7
flutter --version
```

Claude Code gets the official plugin and its skills:

```
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
```

OpenCode has no Flutter plugin marketplace, so keep the `dart mcp-server` entry in `opencode.json` and install the official skills into the workspace:

```
npx skills add flutter/agent-plugins --skill '*' --agent universal --yes
npx skills add dart-lang/skills --skill '*' --agent universal --yes
```

#### Project skills

The project skills in `.claude/skills/` (dotnet, flutter, postgres, software-architecture) are loaded into every session of both agents: `CLAUDE.md` imports them and `opencode.json` lists them under `instructions`. When you add a skill, add it to both files. `AGENTS.md` wins where a skill disagrees with it.

#### Sentry MCP

Sentry MCP is available in two forms. Claude Code uses the hosted server configured in `.mcp.json`. OpenCode 2
currently fails the hosted server's OAuth with a 401 ([anomalyco/opencode#56195](https://github.com/anomalyco/opencode/issues/56195)),
so the dev shell provides a local stdio server instead. **Temporary workaround:** remove the `sentry-mcp`
wrapper from `flake.nix` and point `opencode.json` back at `https://mcp.sentry.dev/mcp` once that issue is fixed.

```
sentry-mcp auth login     # once; opens the browser and stores the login
```

`opencode.json` starts the `sentry-mcp` wrapper, which defaults to `MCP_SKILLS=inspect,triage`; the local server then uses the stored
login. `sentry-cli` is also in the shell for releases and debug-symbol uploads. Without an LLM provider the
local server's AI-powered search tools are unavailable, but project/DSN discovery and the other tools work.
If you need `project-management` for a setup task, run it explicitly with
`MCP_SKILLS=inspect,triage,project-management sentry-mcp` and re-authorize; never commit a token.

#### Scaleway MCP

Scaleway's own MCP server is built into the Scaleway CLI (`scw mcp server serve`). The `scw-mcp` wrapper in the dev shell
starts it read-only (`read-only=true`), so only get and list commands exist, and limits it to the namespaces `instance`, `rdb`, `dns`,
`object`, `iam`, `registry` and `vpc`. Both agents register it as `scaleway`.

It runs under the CLI profile named by `SCW_PROFILE`, `velomine-readonly` by default. Create the key for it once:

1. In the Scaleway console, create an IAM application for agents, with a policy scoped to the Velomine project.
2. Give the policy read-only permission sets only: `InstancesReadOnly`, `RelationalDatabasesReadOnly`,
   `DomainsDNSReadOnly`, `ObjectStorageReadOnly`, `IAMReadOnly`, `ContainerRegistryReadOnly` and `VPCReadOnly`.
3. Generate an API key for the application and store it as a profile: `scw init -p velomine-readonly`.

Never use the account key, and never commit a key. Changes to the infrastructure go through OpenTofu in `infra/`, never through the MCP.

The dev shell points the NuGet, pub, Gradle and Android caches, and the unpacked Flutter SDK into `.dev/`. Ride files, the database and the Data Protection keys live in Docker volumes.

### 6. Enter the dev shell for the first time

From the repository folder:

```
direnv allow
```

direnv refuses to run an `.envrc` until you allow it, because `.envrc` is a shell script. `direnv allow` marks this one as trusted. Run it again after anyone changes `.envrc`. Nix then reads `flake.nix` and downloads everything: the .NET SDK, the Android SDK with its emulator image, Java, Node and the Flutter tarball. **The first run downloads several GB and can take a while.** Afterwards, the shell unpacks Flutter into `.dev/` and restores `dotnet-ef`.

When it is done, check:

```
which dotnet         # a path under /nix/store
flutter --version    # Flutter 3.47.9, Dart 3.13.7
```

If Nix says a file "does not exist" although you can see it, git does not track it yet. See *Troubleshooting*.

### 7. Project setup

```
just setup
codegraph telemetry off
codegraph init
```

- `just setup` restores the .NET tools, fetches the Flutter packages (`flutter pub get`) and creates an Android emulator named `velomine`: a 1080×2400 phone at 420 dpi, the most common Android screen in use.
- `codegraph telemetry off` is a one-time setting per machine. `codegraph init` builds the code index in `.codegraph/`, which is git-ignored.

### 8. Try it

```
just up              # build and start PostgreSQL, Dex and the server in Docker
```

Open http://localhost:8080 and sign in as `admin@velomine.local` / `Velomine-dev-1`. The server, the web app and the site run only in Docker, built from your working folder: after a change, run `just up` again. For Android:

```
just emu             # start the emulator if needed and run the app on it
```

Open the repository folder in VS Code and allow the `.envrc` when the direnv extension asks.

### Other systems

Nix also runs on other Linux distributions, macOS and WSL 2. Install it with the [official installer](https://nixos.org/download/), turn on flakes as in step 2, and continue from step 3. This has only been tried on CachyOS. The flake currently builds for `x86_64-linux` only.

## Telemetry in development

Telemetry is off by default. To send it locally, put the values in the git-ignored `.dev/telemetry.env`; the
`server` service in `docker-compose.yml` reads that file when it exists. Run `just up` after changing it:

```
VELOMINE__TELEMETRY__ENABLED=true
VELOMINE__TELEMETRY__SENTRY__DSN=<server dsn>
VELOMINE__TELEMETRY__SENTRY__APPDSN=<app dsn>
VELOMINE__TELEMETRY__SENTRY__ENVIRONMENT=development
VELOMINE__TELEMETRY__TRACESAMPLERATIO=1
```

The server starts logs, traces, metrics and errors. The phone reads the app DSN from `GET /api/v1/server`, but only
after a member opts in under **Profile → Privacy** and restarts the app. If `AppDsn` is unset it falls back to
`Dsn`, so one project still works. A self-hosted server with no DSN sends nothing. The app also reports its own
sign-in, recording, upload and API signals through the same consent switches.

Release builds do not upload debug symbols or web source maps yet. When you want readable release stack traces,
add the Sentry Dart Plugin and pass `SENTRY_AUTH_TOKEN` as a build secret; it is deliberately not enabled by
default because a self-hosted image has no token.

## Daily work

Enter the folder and the shell loads. Run `just` on its own to list every command.

| Command | What it does |
|---------|--------------|
| `just up` | Builds the image and starts PostgreSQL, Dex and the server in Docker on http://localhost:8080, exactly as `docker compose up --build` in the README, in the background. Run it again after any change. |
| `just logs` | Follows the server's log |
| `just down` / `just nuke` | Stops the containers. `nuke` also deletes the database, the ride files and the Data Protection keys. |
| `just db` | Opens psql on the database inside the postgres container |
| `just emu` | Runs the app on the Android emulator against the stack from `just up`, starting the emulator first if it is not running. `adb reverse` forwards ports 8080 and 5556, so the app reaches the server and Dex at `localhost`. |
| `just phone [ip:port]` | Runs the app on a real phone over Wi-Fi adb, with the same port forwarding. Turn on *Wireless debugging* on the phone and pair it once (`adb pair`); then `just phone 192.168.1.20:5555` connects and runs, and plain `just phone` uses a phone that is already connected. |
| `just migration Name` | Adds an EF Core migration under `Data/Migrations` |
| `just api-client` | Regenerates the Dart API client after an endpoint change (`tools/generate-api-client.sh`) |
| `just codegen` | Regenerates the Riverpod providers (`build_runner`). Run it after changing a `@riverpod` provider; the generated `.g.dart` files are committed. |
| `just check` | Runs every check before a commit: .NET format check, server tests, Riverpod codegen, Dart format, analyzer and Flutter tests |
| `nix fmt flake.nix` | Formats the flake with the pinned `nixfmt` |

There is one way to run Velomine, in development and for a self-hoster alike: `docker-compose.yml`. Nothing runs the server from your shell. `flutter run -d chrome` still works for quick UI work, but password sign-in needs the cookie, which only works when the server serves the app, so use `just up` for anything that needs a session.

## Updating tools

- **Flutter:** change `flutterVersion` and `sha256` in `flake.nix` **and** `FLUTTER_VERSION` and `FLUTTER_SHA256` in the `Dockerfile`, in the same commit. Take both values from Flutter's [release list](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json). Run `direnv reload`. The new version unpacks into its own `.dev/flutter-<version>` folder, so delete the old one. A new minor version (3.48 rather than 3.47.x) may ask for newer Android SDK or NDK versions. See *Troubleshooting*.
- **Everything from nixpkgs** (.NET SDK, Java, Node, CodeGraph, just, the Android packages): `nix flake update nixpkgs`, then commit the new `flake.lock` on its own.
- **Claude Code:** pinned in `flake.nix` ahead of nixpkgs. Take the version from `https://downloads.claude.ai/claude-code-releases/latest` and the `linux-x64` checksum from `https://downloads.claude.ai/claude-code-releases/<version>/manifest.zst.json`, and set both in `claudeCode`. Then set the VS Code extension's `hash` in `claudeCodeExtension` to `pkgs.lib.fakeHash`, run `nix build .#vscode`, and paste the hash it reports. Commit both together. Drop the overrides once nixpkgs' `claude-code` has caught up.
- **Agent plugins:** OpenCode updates ponytail with `opencode plugin update @dietrichgebert/ponytail`; change the pinned version in `opencode.json` after reading the changelog. Claude Code's plugins (ponytail, the official Flutter plugin) update through `claude plugin update`.
- **Before committing a flake change:** run `nix fmt flake.nix` and `nix flake check --no-build`.

## Troubleshooting

| Problem | What to do |
|---------|-----------|
| `experimental Nix feature 'nix-command' is disabled` | Step 2's `experimental-features` line is missing from `/etc/nix/nix.conf`. Add it and restart `nix-daemon.socket`. |
| `usermod: group 'nix-users' does not exist` | Arch does not have that group and you don't need it. Leave it out of `usermod`. |
| Nix says `flake.nix` (or another file) does not exist | Inside a git repository, Nix only sees files git tracks. `git add` the file; you don't have to commit it. |
| `/usr/share/nix-direnv/direnvrc: No such file` | `nix-direnv` is not in the Arch repositories. Run `nix profile install nixpkgs#nix-direnv`, then source `~/.nix-profile/share/nix-direnv/direnvrc` in `~/.config/direnv/direnvrc` (step 3). |
| No `kvm` group | Check `ls -l /dev/kvm`. `crw-rw-rw-` means everyone can use it and you don't need the group. If `/dev/kvm` is missing, turn on Intel VT-x or AMD SVM in the firmware settings and check `lsmod \| grep kvm`. Inside the shell, `emulator -accel-check` tells you whether acceleration works. |
| The emulator window stays black | Start it with software rendering: `emulator -avd velomine -gpu swiftshader_indirect`. |
| Gradle wants an SDK component or NDK version that is not installed | The SDK in `/nix/store` is read-only, so Gradle cannot install anything into it. Add the exact version it names to the `android` block in `flake.nix` (`platformVersions`, `buildToolsVersions` or `ndkVersions`) and run `direnv reload`. |
| `flutter run -d chrome` finds no browser | Install Chromium or Chrome on the host. The shell sets `CHROME_EXECUTABLE` to the first one it finds. |
| The Dart MCP server is missing in OpenCode, or `opencode mcp list` says `NotFound` | OpenCode's background service was started outside the dev shell and is spawning the server without `dart` on PATH. Run `direnv reload`, then `opencode service restart` from the repository, and start a new session. The desktop app must connect to that service (see *OpenCode desktop*), not to the local server it starts itself. |
| Single sign-on through Dex fails | Dex only accepts `http://localhost:8080/signin-oidc`: keep `VELOMINE_PORT` at 8080, or change the redirect address in `deploy/dex/config.yaml` too. |
| `port is already allocated` on 8080 | Another program uses the port. Stop it, or set `VELOMINE_PORT` in `.env`. |
| Something in the shell is broken or stale | `rm -rf .dev .direnv`, then `direnv allow`. Caches download again, and nothing in git is affected. |

## Removing it

Delete `.dev/` and `.direnv/` in the repository. To remove Nix completely, uninstall the host packages from step 1, delete `/nix` and remove the lines added in steps 2 and 3. A few small settings files stay in your home folder (`~/.config/flutter` and `~/.dart-tool`), plus the Docker images and volumes (`just nuke`, `docker image prune`).
