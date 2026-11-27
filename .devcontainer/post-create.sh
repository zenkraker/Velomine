#!/usr/bin/env bash
# Runs once when the dev container is created. Everything here stays in the container.
set -euo pipefail

# Node comes from the node feature's nvm, which only login shells get on PATH; this script is not one.
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Volumes start owned by root.
sudo chown -R "$(id -u):$(id -g)" "$HOME/.state"
mkdir -p "$HOME/.state"/{claude,pi,config,data,state,cache}

# Copy the defaults in config/ into the volume. Files that are already there are kept, so logins and
# your own changes survive a rebuild. Never put credentials in config/ (see config/README.md).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
seed() { # source folder, target folder
  local src="$1" dst="$2" file rel
  while IFS= read -r -d '' file; do
    rel="${file#"$src"/}"
    if [ ! -e "$dst/$rel" ]; then
      mkdir -p "$(dirname "$dst/$rel")"
      cp "$file" "$dst/$rel"
    fi
  done < <(find "$src" -type f ! -name README.md ! -name .gitkeep -print0)
}
seed "$here/config/claude" "$HOME/.state/claude"
seed "$here/config/pi" "$HOME/.state/pi"

# The agent programs that are npm packages, into the volume so they survive a rebuild and are on PATH through
# the image's PATH (Dockerfile): Claude Code, the local Sentry MCP server Pi starts, and the Playwright MCP server, the
# agents' browser. Update them deliberately. CodeGraph, the Sentry CLI and the Scaleway CLI are in the image (Dockerfile).
npm install -g --prefix "$HOME/.state/npm-global" \
  @anthropic-ai/claude-code@2.1.329 \
  @sentry/mcp-server@0.49.0 \
  @playwright/mcp@0.0.86

# Playwright's headless Chromium, the exact build the Playwright inside the MCP server asks for, into the cache volume
# (PLAYWRIGHT_BROWSERS_PATH in devcontainer.json). The libraries it needs are in the image (Dockerfile).
"$HOME/.state/npm-global/lib/node_modules/@playwright/mcp/node_modules/.bin/playwright" install --only-shell chromium

echo "velomine: dev container ready."
