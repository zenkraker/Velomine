# @dietrichgebert/ponytail 5.3.3

## Need

Keeps the AI agent's changes small: the smallest change that fully solves the task, stdlib and existing project code before new code, and a test for new logic. Without it, an agent tends to invent abstractions and dependencies the repository does not need.

The platform (Claude Code, OpenCode) provides no built-in ruleset for this; the alternative is repeating the rules by hand in `AGENTS.md`.

## Alternatives considered

- **No plugin, rules only in `AGENTS.md`.** Already the fallback and still applies, but it gives no level switching, no `/ponytail-review` or `/ponytail-audit`, and every repository pays the prompt tokens instead of only the sessions that want it.
- **Writing our own rules.** Possible, but the evaluation of review, audit and debt commands is real work for no gain over an MIT-licensed package.
- **Other agent rule packs.** Community packages of the same kind, without the OpenCode server-plugin adapter.

## Licence

MIT. Compatible with Velomine's licence.

## Maintenance

- Last release date: 2026-10-29 (5.3.3).
- Commit activity in the last 12 months: continuous since the first npm release in June 2026; 369 commits on `main`, and five releases between 5.2.0 and 5.3.3.
- Number of active maintainers: one primary maintainer (Dietrich Gebert) plus outside contributors. Bus factor 1.
- Open issues and pull requests; how fast they are answered: 79 open issues and 112 open pull requests at evaluation time (2026-11-09). The project answers issues, but there is no support commitment.

## Security

- Known advisories or CVEs: none known at evaluation time.
- Transitive dependencies it brings in: none. `package.json` has no runtime dependencies.
- What it touches: its own package files, `~/.config/opencode/.ponytail-active` and `~/.config/ponytail/config.json`. The OpenCode plugin runs in the server process, reads the package's `hooks/`, `skills/` and `.opencode/command/` and appends text to the system prompt. No telemetry and no network access beyond the npm install.

## Platform support

- OpenCode 2: server plugin (`.opencode/plugins/ponytail.mjs`), loaded from the `plugins` array. Registers the six commands and skills; the ruleset arrives through the `context` and `compaction` hooks.
- Claude Code: plugin through its marketplace, with Node lifecycle hooks.
- Instruction-only fallback: `AGENTS.md` from the package, for agents without plugin support.

## Size and performance

One small npm package: hooks, six skills and one OpenCode plugin file, no dependencies. Runtime cost is one extra system-prompt block per turn and one file read for the level.

## Risk and exit plan

If it is abandoned, the repository keeps working: `AGENTS.md` still carries the project's rules, and the package is instruction text plus three small hooks. To remove it, delete the `plugins` entry in `opencode.json` (and `/plugin remove ponytail` in Claude Code) and delete `~/.config/opencode/.ponytail-active` and `~/.config/ponytail/config.json`. No repository code depends on it.

## Recommendation

Approve with conditions: agent plugin only, exact version pinned in `opencode.json`, and its rules never override `AGENTS.md`. Re-evaluate on a major update or a change of maintainer.
