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

**Caches go to `.dev/`, not to your home folder.** NuGet, pub and Gradle write into their caches while they run, so the caches cannot live in the read-only store. The dev shell redirects them into `.dev/` in the repository, together with the unpacked Flutter SDK, the emulator and uploaded ride files. `.dev/` is git-ignored. Delete it and all of that is gone. Your lock files (`packages.lock.json`, `pubspec.lock`, `flake.lock`) still pin every version.

### What lives where

| Place | What | Why there |
|-------|------|-----------|
| Your distribution (pacman, apt, …) | Nix, direnv, Docker, VS Code, a Chromium-based browser, a database GUI | Used across all projects, or system services Nix cannot run |
| `flake.nix` (in `/nix/store`) | .NET SDK, Flutter tarball, Android SDK, Java, Node, psql, CodeGraph, OpenCode, VS Code with extensions, just | Versions that matter to this project |
| `.dev/` in the repository | Caches, unpacked Flutter, emulator, ride files | Machine-local and writable; safe to delete |
| Docker | PostgreSQL and Dex | The same containers as `docker compose`; see [the compose file](../docker-compose.yml) |

## What the flake provides

| Tool | Version | Why |
|------|---------|-----|
| .NET SDK | 10.0 (from nixpkgs) | Server and tests. EF Core tools come from `dotnet-tools.json`, restored when the shell starts. |
| Flutter | 3.47.9 with Dart 3.13.7 | The official release with the **same version and checksum as the `Dockerfile`**. Not the nixpkgs build, which lags behind (3.47.4 with Dart 3.13.3, too old for `app/pubspec.yaml`). It is unpacked once into `.dev/`, because Flutter writes into its own folder. |
| Android SDK | platform 36, build tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1, emulator, Play Store image (x86_64) | The versions Flutter 3.47's Gradle plugin asks for |
| Java | JDK 17 | Gradle 9 and the Android Gradle Plugin 9 need Java 17 or newer. It also runs the OpenAPI generator JAR. |
| Node.js | from nixpkgs | Ponytail's Claude Code hooks (see [AGENTS.md](../AGENTS.md)) |
| CodeGraph | from nixpkgs | Required by AGENTS.md, so there's no `curl … \| sh` install |
| OpenCode | from nixpkgs | AI coding agent, an alternative to Claude Code |
| VS Code | 1.144 with the project's extensions | `nix run .#vscode`: Dart/Flutter, Nix IDE, direnv, C# Dev Kit, Claude Code and OpenCode V2. It is the same Microsoft build as `visual-studio-code-bin`. |
| psql | 17 | Same major version as the `postgres:17` container |
| just | from nixpkgs | Runs the commands in the `justfile` |
| nixd | from nixpkgs | Language server for editing `flake.nix` |

Agent plugins are not part of the dev shell: ponytail and the official Flutter plugin (Flutter/Dart skills plus the `dart mcp-server` MCP server) are installed in each agent itself. Step 5 has the details.

The flake targets `x86_64-linux`. iOS builds need macOS with Xcode, which this setup cannot provide.

## Set up (Arch Linux and CachyOS)

These are one-time steps per machine. The commands use fish, the CachyOS default. In bash or zsh, only step 3 changes.

### 1. Install the host packages

```
sudo pacman -S nix direnv docker docker-compose docker-buildx chromium dbeaver
paru -S visual-studio-code-bin
```

- `nix` is the package manager. `direnv` loads the dev shell when you enter the folder; step 3 adds `nix-direnv`, which caches the shell and keeps its packages from being garbage-collected.
- `docker`, `docker-compose` and `docker-buildx` run PostgreSQL and Dex, the tests' Testcontainers, the full stack, and the OpenAPI generator.
- `chromium` is used by `flutter run -d chrome`. Google Chrome works as well.
- `dbeaver` is a GUI for browsing the database. Any PostgreSQL client works. Desktop apps go on the host because GUI programs from Nix often have graphics problems outside NixOS.
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

The flake also builds the same VS Code with those extensions, plus Claude Code and OpenCode V2: run `nix run .#vscode` from the repository. It keeps your normal VS Code settings, and its extensions come from the flake instead of the Marketplace.

### 5. Install Claude Code

Install [Claude Code](https://claude.com/claude-code) as its documentation describes, then start it from the repository folder, so the ponytail hooks find Node from the dev shell. Accept the ponytail marketplace and plugin when it asks (see [AGENTS.md](../AGENTS.md)). The status line shows `[PONYTAIL NOT INSTALLED]` until it is set up. To install it by hand:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Ponytail keeps changes small (smallest complete change, YAGNI, stdlib first). Its hooks need `node`, which the dev shell provides. Useful commands: `/ponytail-review` before a PR, `/ponytail-audit` for the whole repo, `/ponytail-debt` to list `shortcut:` comments.

CodeGraph indexes the code into a local symbol graph and gives Claude MCP tools (`codegraph_explore`, `codegraph_search`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`). `.mcp.json` starts its server and `.claude/settings.json` runs its prompt hook, so `codegraph` must be on PATH when Claude Code starts: start it from the dev shell. Without Nix, install it with `curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`.

OpenCode reads `AGENTS.md` directly and takes its MCP servers and plugins from `opencode.json`; Claude Code reads the same rules through `CLAUDE.md` and its MCP servers from `.mcp.json`. OpenCode needs no install command for ponytail: the `plugins` entry loads `@dietrichgebert/ponytail` from npm on first start and keeps it active in every session of this repository. Both start the Dart MCP server with `dart mcp-server`, which ships with the pinned Flutter SDK: start the agent from the dev shell (with direnv loaded) so `dart` and `FLUTTER_ROOT` are set. For OpenCode that includes its background service, which spawns MCP servers: after a `direnv reload`, restart it with `opencode service restart` from the repository. The first launch resolves the server package into the pub cache in `.dev/`. Install the official Flutter agent plugin (the Flutter/Dart skills plus that MCP server) in each agent as [Flutter's AI setup](https://docs.flutter.dev/ai/get-started) describes; the dev shell provides the SDK, not the agent's skills.

The dev shell points the NuGet, pub, Gradle and Android caches, the unpacked Flutter SDK and the server's ride files into `.dev/`.

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

- `just setup` restores the .NET tools, fetches the Flutter packages (`flutter pub get`) and creates an Android emulator named `velomine`.
- `codegraph telemetry off` is a one-time setting per machine. `codegraph init` builds the code index in `.codegraph/`, which is git-ignored.

### 8. Try it

```
just server          # PostgreSQL and Dex in Docker, then the server with hot reload
```

In a second terminal:

```
just web             # build the web app into the server's wwwroot
```

Open http://localhost:8080 and sign in as `admin@velomine.local` / `Velomine-dev-1`. For Android:

```
just emu             # start the emulator; wait until it has booted
just android         # run the app on it
```

Open the repository folder in VS Code and allow the `.envrc` when the direnv extension asks.

### Other systems

Nix also runs on other Linux distributions, macOS and WSL 2. Install it with the [official installer](https://nixos.org/download/), turn on flakes as in step 2, and continue from step 3. This has only been tried on CachyOS. The flake currently builds for `x86_64-linux` only.

## Daily work

Enter the folder and the shell loads. Run `just` on its own to list every command.

| Command | What it does |
|---------|--------------|
| `just server` | Starts PostgreSQL and Dex in Docker, then runs the server with `dotnet watch` on http://localhost:8080, with the same admin and single sign-on settings as `docker-compose.yml` |
| `just web` | Builds the Flutter web app into `src/Velomine.Server/wwwroot`, so the server serves it at the same address and the session cookie works. Run it again after app changes, then reload the page. |
| `just emu` | Starts the Android emulator |
| `just android` | Runs the app on the emulator. `adb reverse` forwards port 8080, so the app reaches your server at `localhost:8080`. |
| `just stack` | Runs the whole stack in Docker, exactly as the README describes. Don't run it at the same time as `just server`: both use port 8080. |
| `just down` / `just nuke` | Stops the containers. `nuke` also deletes the database and the uploaded ride files. |
| `just db` | Opens psql on the dev database |
| `just migration Name` | Adds an EF Core migration under `Data/Migrations` |
| `just api-client` | Regenerates the Dart API client after an endpoint change (`tools/generate-api-client.sh`) |
| `just codegen` | Regenerates the Riverpod providers (`build_runner`). Run it after changing a `@riverpod` provider; the generated `.g.dart` files are committed. |
| `just check` | Runs the README's checks: server tests, Riverpod codegen, Dart format, analyzer and Flutter tests |
| `nix fmt flake.nix` | Formats the flake with the pinned `nixfmt` |

`flutter run -d chrome` also works for quick UI work. Password sign-in needs the cookie, which only works when the server serves the app, so use `just web` for anything that needs a session.

`compose.dev.yml` is used only by the `just` commands. It adds one thing to `docker-compose.yml`: PostgreSQL on `127.0.0.1:5432`, so a server running in your shell can reach it with the connection string in `appsettings.json`.

## Updating tools

- **Flutter:** change `flutterVersion` and `sha256` in `flake.nix` **and** `FLUTTER_VERSION` and `FLUTTER_SHA256` in the `Dockerfile`, in the same commit. Take both values from Flutter's [release list](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json). Run `direnv reload`. The new version unpacks into its own `.dev/flutter-<version>` folder, so delete the old one. A new minor version (3.48 rather than 3.47.x) may ask for newer Android SDK or NDK versions. See *Troubleshooting*.
- **Everything from nixpkgs** (.NET SDK, Java, Node, psql, CodeGraph, just, the Android packages): `nix flake update nixpkgs`, then commit the new `flake.lock` on its own.
- **Agent plugins:** OpenCode updates ponytail with `opencode plugin update @dietrichgebert/ponytail`; change the pinned version in `opencode.json` after reading the changelog. Claude Code and the official Flutter plugin update through their own plugin commands.
- **Before committing a flake change:** run `nix fmt flake.nix` and `nix flake check --no-build`.
- **PostgreSQL:** psql's major version follows the `postgres` image in `docker-compose.yml`. Change both together.

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
| The Dart MCP server is missing in OpenCode, or `opencode mcp list` says `NotFound` | OpenCode's background service was started outside the dev shell and is spawning the server without `dart` on PATH. Run `direnv reload`, then `opencode service restart` from the repository, and start a new session. If the desktop app starts the service itself, quit it fully first and relaunch it from the dev shell. |
| Single sign-on through Dex fails with `just server` | Port 8080 must be free (no `just stack` running), because Dex only accepts `http://localhost:8080/signin-oidc`. |
| Port 5432 is already in use | A PostgreSQL on the host is running. Stop it, or change the port in `compose.dev.yml` and pass a matching `ConnectionStrings__Velomine`. |
| Something in the shell is broken or stale | `rm -rf .dev .direnv`, then `direnv allow`. Caches download again, and nothing in git is affected. |

## Removing it

Delete `.dev/` and `.direnv/` in the repository. To remove Nix completely, uninstall the host packages from step 1, delete `/nix` and remove the lines added in steps 2 and 3. A few small settings files stay in your home folder (`~/.config/flutter`, `~/.dart-tool`, and `~/.aspnet` for ASP.NET's cookie keys), plus the Docker images and volumes (`just nuke`, `docker image prune`).
