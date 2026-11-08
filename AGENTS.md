# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

- **Server:** .NET 10 (LTS), ASP.NET Core, EF Core, PostgreSQL.
- **Apps:** Flutter for mobile (Android, iOS) and for the web app (Flutter web), one shared Dart codebase.
- **Share pages and landing page:** plain HTML rendered by the server.

These rules apply to every app and project in this repository: server, mobile, web, tools and scripts.

## What belongs in this file

`AGENTS.md` holds **only invariants**: code, architecture, dependency and tooling rules that stay true for as long as nobody decides otherwise. **Never** put project status here: progress, roadmap position, current release, open questions, to-do lists or "what's done". Those go in `README.md`. When a rule here changes, edit it in place; do not add a history. `CLAUDE.md` imports this file, so Claude Code reads the same rules.

## References

Background documents. Read the relevant one before designing a feature. When a document and this file disagree, this file wins.

| Document | Read it for |
|----------|-------------|
| `docs/architecture.md` | System architecture: modules, ingestion pipeline, jobs, data model, API, security, apps |
| `docs/design/v1-scope-and-architecture.md` | Product scope, feature decisions, tech stack and architecture |
| `docs/design/brand-directions.html` | Brand: name, colours, type and day/night themes (open in a browser) |
| `docs/development.md` | The Nix development environment: how it works, setup (including Claude Code, OpenCode, ponytail, CodeGraph and the Flutter/Dart MCP server), daily commands, updating tools |
| `docs/dependencies/` | Dependency evaluations, the template, approved and pending libraries |

## Architecture invariants

- **Keep it simple.** One server, one PostgreSQL database, one file volume. No microservices, brokers, caches or extra services.
- **Vertical slices.** Server code lives in `Features/<Area>/`, one file per use case (request, response, validation, endpoint, logic). Slices use the `DbContext` directly: no repositories, service layers or mediators.
- **Endpoints use FastEndpoints**, one endpoint class per slice.
- **Background work runs in the server** as hosted services. PostgreSQL is storage only: no job queues, events or outbox in the database.
- **One PostgreSQL schema per feature area.**
- **Don't reinvent the wheel on .NET.** Use what .NET, ASP.NET Core, EF Core and official Microsoft libraries provide; write it yourself only when nothing official fits.
- **Every endpoint declares what it really accepts and returns** (`Description(...)` in its `Configure()`), because the generated Dart client is only as accurate as the OpenAPI document. After changing an endpoint, run `tools/generate-api-client.sh` and commit the regenerated client.
- **The web app is served by the server** from `wwwroot`, at the same address as the API (built by the Dockerfile), so its session cookie needs no cross-origin setup.
- **The Dart API client is generated** from the server's OpenAPI document. Never edit generated files by hand. For the generator only, a community tool is acceptable if it is free, well documented and actively supported; it still needs an evaluation in `docs/dependencies/`.

## Tests

- **Every test name follows `Subject_ShouldDoSomething_WhenCondition`.** Three PascalCase parts separated by underscores: the method, class, screen or controller under test, the observable behaviour, and the condition that triggers it. This applies to xUnit test methods and to the description strings of Dart `test(...)` and `testWidgets(...)`; group labels stay descriptive prose.
- **Examples.** `NormalizedPower_ShouldReturnThatPower_WhenPowerIsSteady`, `SignInScreen_ShouldExplainWrongPassword_WhenSignInFails`, `MapView_ShouldZoomInMoreForShortRoutes_WhenFittingTheRoute`. Avoid spaces, punctuation and vague subjects like `Test1`.

## Development environment

- **`flake.nix` is the toolchain.** A tool needed to develop, build or test goes into the flake. Don't add install instructions, scripts that install into the home folder, or host requirements for it. Adding a tool is still a dependency and follows the dependency rule below.
- **Running needs Docker only.** `docker compose up --build` must keep working without Nix. The `Dockerfile` and the compose stack do not use Nix.
- **Versions agree everywhere.** The Flutter version and checksum in `flake.nix` and in the `Dockerfile` change in the same commit. psql in the flake has the same major version as the `postgres` image. The Android SDK, NDK and CMake versions in the flake are the ones the pinned Flutter's Gradle plugin asks for.
- **Commit `flake.lock`.** Update nixpkgs with `nix flake update` in a commit of its own.
- **Machine-local state stays in `.dev/`** (git-ignored). Never commit anything from it, and never send a tool's cache or data elsewhere.
- **The `justfile` is the entry point for everyday commands.** A command developers run repeatedly gets a recipe. `compose.dev.yml` is only for `just` and only publishes ports for the host.

## AI coding agents

- **The ponytail plugin is mandatory for Claude Code** (enabled in `.claude/settings.json`). Never turn it off for work on this repository.
- **CodeGraph is mandatory** (wired up by `.mcp.json` and `.claude/settings.json`). When a `.codegraph/` directory exists, use `codegraph_explore` or `codegraph explore "<symbols or question>"` before grep or reading files; `.claude/CLAUDE.md` has the details.
- **Flutter and Dart work uses the Dart MCP server and the official Flutter/Dart skills.** Start the agent from the dev shell, so `dart` and `FLUTTER_ROOT` are set; `.mcp.json` (Claude Code) and `opencode.json` (OpenCode) then start `dart mcp-server`. The flake links the official skills into `.claude/skills/` (names starting `flutter-` or `dart-`). Use its analyzer, test, runtime and hot-reload tools to check the real project instead of guessing, and load the matching skill before writing widgets, tests, routing, localization or layout code. After editing a `.dart` file under `app/lib/`, trigger `hot_reload` (or `hot_restart` after `initState`, global state or `main` changes) when an app is running.
- Setup for all of these is in `docs/development.md`.

## Dependency rule: official libraries first

**Never add a dependency without following this section.** The skills in `.claude/skills/`, including the official Flutter/Dart ones, never override it. This covers runtime packages, build tools, test libraries, linters, code generators, CI actions and container base images.

### 1. Prefer what the platform already gives you

Before adding anything, check whether the need is covered by:

1. The language or framework itself (.NET base class library, ASP.NET Core, EF Core, Dart SDK, Flutter SDK).
2. Code we can reasonably write and maintain ourselves.

### 2. Official libraries: allowed

A library is **official** when it is published and maintained by the owner of the platform, framework, protocol or service it targets. Examples:

- **.NET:** packages published by Microsoft or the .NET team (`Microsoft.*`, `System.*`).
- **Flutter / Dart:** packages from the verified publishers `flutter.dev` and `dart.dev` on pub.dev.
- **Vendors, for their own formats and services:** for example `Garmin.FIT.Sdk` for FIT files, published by Garmin.

Official libraries can be added without approval, but you must still:

- pin the version and commit the lock file;
- state in the PR or commit message which library was added and why.

**If you are not sure a library is official, treat it as community.**

### 3. Community libraries: evaluate, then ask

Any library that is not official is a **community library**. You must **not** add it, install it, or write code against it until the owner has approved it.

Do this instead:

1. Write an evaluation in `docs/dependencies/<package-name>.md` using the template in `docs/dependencies/TEMPLATE.md`.
2. Stop and ask the owner for approval, linking the evaluation.
3. Wait. Do not add the package "temporarily", in a branch, or behind a flag.

Commands like `dotnet add package`, `flutter pub add`, `dart pub add` and `npm install` for a community package are forbidden until approval is recorded.

### 4. Record decisions

- Approved community libraries are listed in `docs/dependencies/APPROVED.md` with the approved version, date and a link to the evaluation.
- Rejected ones stay in `docs/dependencies/` with the rejection reason, so they are not proposed again without new facts.

### 5. Updates

- Patch and minor updates of an approved library: allowed; mention them in the commit message.
- Major updates, or a change of maintainer or licence: re-evaluate and ask again.
- Removing a dependency never needs approval.

Pending evaluations are listed in `docs/dependencies/APPROVED.md`.
