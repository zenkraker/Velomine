#!/usr/bin/env bash
# Fails when the pinned Flutter release differs between flake.nix, app/Dockerfile (the web image) and
# .devcontainer/Dockerfile (the dev container).
# AGENTS.md: "The Flutter version and checksum in flake.nix and the Dockerfile change in the same commit."
# CI reads the pin from app/Dockerfile (.github/actions/setup-flutter), so it is the reference.
set -euo pipefail
cd "$(dirname "$0")/.."

flake_version="$(sed -n 's/^ *flutterVersion = "\(.*\)";/\1/p' flake.nix)"
flake_sha="$(sed -n '/flutterTarball/,/};/s/^ *sha256 = "\(.*\)";/\1/p' flake.nix)"
docker_version="$(sed -n 's/^ARG FLUTTER_VERSION=//p' app/Dockerfile)"
docker_sha="$(sed -n 's/^ARG FLUTTER_SHA256=//p' app/Dockerfile)"
devcontainer_version="$(sed -n 's/^ARG FLUTTER_VERSION=//p' .devcontainer/Dockerfile)"
devcontainer_sha="$(sed -n 's/^ARG FLUTTER_SHA256=//p' .devcontainer/Dockerfile)"

status=0
check() { # what, reference, other, other's name
  if [[ -z "$2" || "$2" != "$3" ]]; then
    echo "Flutter $1 differs: app/Dockerfile '${2}' vs ${4} '${3}'" >&2
    status=1
  fi
}
check version "$docker_version" "$flake_version" flake.nix
check checksum "$docker_sha" "$flake_sha" flake.nix
check version "$docker_version" "$devcontainer_version" .devcontainer/Dockerfile
check checksum "$docker_sha" "$devcontainer_sha" .devcontainer/Dockerfile
[[ $status -eq 0 ]] && echo "Flutter ${docker_version}: flake.nix, app/Dockerfile and .devcontainer/Dockerfile agree."
exit $status
