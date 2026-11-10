#!/usr/bin/env bash
# Regenerates the Dart client in app/packages/velomine_api from the server's OpenAPI document.
# Run it after changing an endpoint's request or response, and commit the result.
#
#   tools/generate-api-client.sh                 uses the Docker image openapitools/openapi-generator-cli:v7.26.0
#   OPENAPI_GENERATOR_JAR=/path/to/openapi-generator-cli-7.26.0.jar tools/generate-api-client.sh
#                                                uses that JAR (Java 11+) instead, e.g. where Docker Hub is not reachable
#
# CI regenerates and fails when the committed client differs (see docs/architecture.md).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=7.26.0
OUT=app/packages/velomine_api

# 1. The server writes its OpenAPI document and exits. This needs no database.
# Port 0 lets the OS pick a free port for the moment the server is up, so a busy port 5000 doesn't stop it.
(cd src/Velomine.Server && rm -rf wwwroot/openapi && ASPNETCORE_URLS=http://127.0.0.1:0 dotnet run -- --export-openapi-docs true)
SPEC=src/Velomine.Server/wwwroot/openapi/v1.json

# 2. Generate. The options are the ones approved in AGENTS.md (Approved community libraries).
rm -rf "$OUT"
ARGS=(generate -i "$SPEC" -g dart -o "$OUT"
  --additional-properties="pubName=velomine_api,pubLibrary=velomine_api,pubVersion=1.0.0,pubDescription=Generated client for the Velomine API. Do not edit.,useOptional=true,useFinalProperties=true,enumUnknownDefaultCase=true"
  --global-property="apiTests=false,modelTests=false,apiDocs=false,modelDocs=false")

if [[ -n "${OPENAPI_GENERATOR_JAR:-}" ]]; then
  java -jar "$OPENAPI_GENERATOR_JAR" "${ARGS[@]}"
else
  # Run as the current user, so the generated files are not owned by root (Docker on Linux).
  docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/local" -w /local "openapitools/openapi-generator-cli:v$VERSION" "${ARGS[@]}"
fi

# 3. The Dart generator casts JSON numbers straight to double/int, which throws on
#    native for a whole number (the server writes 79 for 79.0) and for a null in a
#    nullable array. tools/patch_api_client.dart rewrites those casts after generation.
dart tools/patch_api_client.dart

# 4. The generated code is not ours to lint.
printf 'analyzer:\n  exclude:\n    - "**"\n' > "$OUT/analysis_options.yaml"
rm -f "$OUT/.travis.yml" "$OUT/git_push.sh"
