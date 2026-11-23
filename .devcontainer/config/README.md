# Agent defaults for the dev container

Files here are copied into the `velomine-state` volume when the container is created, by `post-create.sh`:

| Folder | Lands in | Used by |
|--------|----------|---------|
| `claude/` | `~/.state/claude` (`CLAUDE_CONFIG_DIR`) | Claude Code: `settings.json`, `CLAUDE.md`, ... |
| `pi/` | `~/.state/pi` (`PI_CODING_AGENT_DIR`) | Pi, also the Pi inside Pendant: `settings.json`, `models.json`, `advisor.json`, ... Never `auth.json` (credentials) |

Pendant's own profiles (subagents) and its other settings are not files here: they are VS Code settings, in `customizations.vscode.settings` of `devcontainer.json`.

- A file that is already in the volume is never overwritten, so your own changes and the logins you made inside the container survive a rebuild. To take a changed default, delete the file in the volume and run `bash .devcontainer/post-create.sh`.
- **Never put credentials here** (Claude's `.credentials.json`, Pi's `auth.json`, API keys, tokens): this folder is committed. Sign in inside the container once (see *Dev container* in `docs/development.md`); the login stays in the volume.
- Project settings, skills and MCP servers (`.claude/`, `.pi/`, `.mcp.json`, `opencode.json`) come with the repository and need nothing here.
