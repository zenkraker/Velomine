# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

- **Server:** .NET 10 (LTS), ASP.NET Core, EF Core, PostgreSQL.
- **Apps:** Flutter for mobile (Android, iOS) and for the web app (Flutter web), one shared Dart codebase.
- **Share pages and landing page:** plain HTML rendered by the server.

These rules apply to every app and project in this repository: server, mobile, web, tools and scripts.

## What belongs in this file

`CLAUDE.md` holds **only invariants**: code, architecture, dependency and tooling rules that stay true for as long as nobody decides otherwise. **Never** put project status here: progress, roadmap position, current release, open questions, to-do lists or "what's done". Those go in `README.md`. When a rule here changes, edit it in place; do not add a history.

## References

Background documents. Read the relevant one before designing a feature. When a document and this file disagree, this file wins.

| Document | Read it for |
|----------|-------------|
| `docs/design/v1-scope-and-architecture.md` | Product scope, feature decisions, tech stack and architecture |
| `docs/research/endurain-feature-analysis-v0.20.2.md` | What Endurain does, its bugs and gaps, and the ride-ingestion design |
| `docs/design/brand-directions.html` | Brand: name, colours, type and day/night themes (open in a browser) |

**Clean-room rule:** Endurain is AGPL-3.0. Take ideas from it, never code. Do not copy, translate or adapt Endurain source, and do not use the Endurain name or logo.

## Claude Code setup

### Ponytail is mandatory

Every developer working on this project must use the **ponytail** plugin (smallest complete change, YAGNI, stdlib first). It is enabled for the project in `.claude/settings.json`; accept the marketplace and plugin when Claude Code prompts you on first start. Manual install:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Do not turn it off for work on this repository. Its hooks need `node` on your PATH. Useful commands: `/ponytail-review` before a PR, `/ponytail-audit` for the whole repo, `/ponytail-debt` to list `shortcut:` comments.

### Code graph

The **code-graph** plugin is also enabled in `.claude/settings.json` (manual install: `/plugin marketplace add jsnavarroc/code-graph`, then `/plugin install code-graph@code-graph`). Use it to map a subsystem you did not write before you refactor it or change its behaviour.

### Project skills

Skills in `.claude/skills/` load automatically when the task matches them:

| Skill | Use for |
|-------|---------|
| `flutter` | Flutter/Dart code for Android, iOS and web |
| `dotnet` | .NET 10, ASP.NET Core and EF Core server code |
| `postgres` | Schema, EF Core migrations, queries, activity data |
| `software-architecture` | Module boundaries, API contracts, self-hosting, ADRs |

The skills never override the dependency rule below.

## Dependency rule: official libraries first

**Never add a dependency without following this section.** This covers runtime packages, build tools, test libraries, linters, code generators, CI actions and container base images.

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

1. Write an evaluation in `docs/dependencies/<package-name>.md` using the template below.
2. Stop and ask the owner for approval, linking the evaluation.
3. Wait. Do not add the package "temporarily", in a branch, or behind a flag.

Commands like `dotnet add package`, `flutter pub add`, `dart pub add` and `npm install` for a community package are forbidden until approval is recorded.

#### Evaluation template

```markdown
# <package name> <version>

## Need
What problem it solves, and why the platform or an official library cannot.

## Alternatives considered
Official options, other community packages, writing it ourselves (rough effort).

## Licence
Licence name, and whether it is compatible with Velomine's licence.

## Maintenance
- Last release date:
- Commit activity in the last 12 months:
- Number of active maintainers:
- Open issues and pull requests; how fast they are answered:

## Security
- Known advisories or CVEs:
- Transitive dependencies it brings in (list them):

## Platform support
- .NET: targets .NET 10 or .NET Standard 2.0+?
- Flutter: Android, iOS and web supported? Any native code?

## Size and performance
Package size, startup or bundle impact, anything measured.

## Risk and exit plan
What happens if it is abandoned; how we would replace it.

## Recommendation
Approve, approve with conditions, or reject, and why.
```

### 4. Record decisions

- Approved community libraries are listed in `docs/dependencies/APPROVED.md` with the approved version, date and a link to the evaluation.
- Rejected ones stay in `docs/dependencies/` with the rejection reason, so they are not proposed again without new facts.

### 5. Updates

- Patch and minor updates of an approved library: allowed; mention them in the commit message.
- Major updates, or a change of maintainer or licence: re-evaluate and ask again.
- Removing a dependency never needs approval.

### Known cases that need an evaluation

- **Bluetooth LE in Flutter:** Flutter has no official BLE plugin. Candidates such as `universal_ble` must be evaluated and approved before the sensor work starts.
