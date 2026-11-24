#!/usr/bin/env bash
# Fails when the pinned Flutter release differs between app/Dockerfile (the web image, and the pin CI reads) and
# .devcontainer/Dockerfile (the development image).
# AGENTS.md: "The Flutter version and checksum in app/Dockerfile and .devcontainer/Dockerfile change in the same commit."
# CI reads the pin from app/Dockerfile (.github/actions/setup-flutter), so it is the reference.
set -euo pipefail
cd "$(dirname "$0")/.."

ref_version="$(sed -n 's/^ARG FLUTTER_VERSION=//p' app/Dockerfile)"
ref_sha="$(sed -n 's/^ARG FLUTTER_SHA256=//p' app/Dockerfile)"
dev_version="$(sed -n 's/^ARG FLUTTER_VERSION=//p' .devcontainer/Dockerfile)"
dev_sha="$(sed -n 's/^ARG FLUTTER_SHA256=//p' .devcontainer/Dockerfile)"

status=0
check() { # what, reference, other, other's name
  if [[ -z "$2" || "$2" != "$3" ]]; then
    echo "Flutter $1 differs: app/Dockerfile '${2}' vs ${4} '${3}'" >&2
    status=1
  fi
}
check version "$ref_version" "$dev_version" .devcontainer/Dockerfile
check checksum "$ref_sha" "$dev_sha" .devcontainer/Dockerfile
[[ $status -eq 0 ]] && echo "Flutter ${ref_version}: app/Dockerfile and .devcontainer/Dockerfile agree."
exit $status
