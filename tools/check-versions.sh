#!/usr/bin/env bash
# Fails when the pinned Flutter release differs between flake.nix and app/Dockerfile (the web image).
# AGENTS.md: "The Flutter version and checksum in flake.nix and the Dockerfile change in the same commit."
# CI reads the pin from app/Dockerfile (.github/actions/setup-flutter), so these two are all there is to compare.
set -euo pipefail
cd "$(dirname "$0")/.."

flake_version="$(sed -n 's/^ *flutterVersion = "\(.*\)";/\1/p' flake.nix)"
flake_sha="$(sed -n '/flutterTarball/,/};/s/^ *sha256 = "\(.*\)";/\1/p' flake.nix)"
docker_version="$(sed -n 's/^ARG FLUTTER_VERSION=//p' app/Dockerfile)"
docker_sha="$(sed -n 's/^ARG FLUTTER_SHA256=//p' app/Dockerfile)"

status=0
check() {
  if [[ -z "$2" || "$2" != "$3" ]]; then
    echo "Flutter $1 differs: flake.nix '${2}' vs app/Dockerfile '${3}'" >&2
    status=1
  fi
}
check version "$flake_version" "$docker_version"
check checksum "$flake_sha" "$docker_sha"
[[ $status -eq 0 ]] && echo "Flutter ${docker_version}: flake.nix and app/Dockerfile agree."
exit $status
