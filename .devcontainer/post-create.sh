#!/usr/bin/env bash
# Runs once when the dev container is created. Everything here stays in the container.
set -euo pipefail

# Make npm available in this non-interactive shell (the Node feature installs it through nvm).
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

# Claude Code, at the version that were current when this was written. Update them deliberately.
# CodeGraph, Sentry CLI and the Scaleway CLI are in the image (Dockerfile); `sentry-mcp` fetches its
# pinned package through npx on first use, as in flake.nix.
npm install -g --prefix "$HOME/.state/npm-global" \
  @anthropic-ai/claude-code@2.1.329

echo "velomine: dev container ready. Missing compared with the flake: nixd and the pi command (the Pendant extension brings its own Pi)."
