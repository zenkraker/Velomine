# Pendant (VS Code extension `cdervis.vscode-pi`) 0.95.0

Background evaluation, written from the extension's public pages (Marketplace, GitHub, pendant.sh guide) on 2026-11-20. Nothing here was tested yet.

## Need
A sidebar chat and diffs for Pi inside VS Code. Pi itself runs fine in a terminal; this only adds an editor view. Neither the platform nor an official library offers one.

## Alternatives considered
- Pi in the integrated terminal: no new dependency, and the `pi` that Pendant brings. This stays the fallback.
- Other community extensions for Pi (`Zetaphor/pi-vscode-extension`, `pithings/pi-vscode`, `m4riok/pi-ide-bridge`): not evaluated.
- Cline (`saoudrizwan.claude-dev`): a second agent loop that needs its own API key.

## Licence
Not open source. Free; the licence lets you inspect your copy but not redistribute it or copy its code. The EULA at pendant.sh/eula was not read, and the licence name is not stated.

## Maintenance
- Last release date: not stated (the releases page is a stub).
- Commit activity in the last 12 months: the GitHub repo `cdervis/Pendant` showed 5 commits on `main`; the source is not published.
- Number of active maintainers: one author seen.
- Open issues and pull requests; how fast they are answered: not seen; issues are public but need a signed-in account.

## Security
- Known advisories or CVEs: none found; not searched in depth.
- Transitive dependencies: unknown (closed source). It bundles its own Pi and optionally downloads a voice model from Hugging Face.
- The guide says it sends no telemetry, remote crash reports, prompts or code to its author, and has no account.
- It does not ask before the agent runs a tool. Its sandbox is off by default and covers only Pi's own tools.

## Platform support
VS Code (Marketplace, Open VSX, VSIX). Over SSH, WSL or a container it runs on the remote side, with that side's Pi configuration. Not browser-based VS Code.

## Size and performance
Not measured.

## Risk and exit plan
It bundles its own Pi that cannot be pointed at another, so the Pi version it ships and the one in the terminal can differ. It is closed source with one visible author. Exit: uninstall it and run `pi` in the terminal; sessions stay in Pi's own folder.

## Recommendation
Approved by the owner on 2026-11-20 for the dev container only, with these conditions: never a requirement of the workflow (Pi in the terminal must keep working), no secrets in prompts, and check which Pi version it runs when `pi-claude-tether` or the `.pi/` setup behaves differently from the terminal.
