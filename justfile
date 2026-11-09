compose := "docker compose -f docker-compose.yml -f compose.dev.yml"
avd := "velomine"
image := "system-images;android-36;google_apis_playstore;x86_64"

# list commands
default:
    @just --list

# one-time setup: .NET tools, Flutter packages, Android emulator
setup:
    dotnet tool restore
    cd app && flutter pub get
    avdmanager list avd -c | grep -qx {{avd}} || echo no | avdmanager create avd -n {{avd}} -k "{{image}}"

# start PostgreSQL and Dex in Docker
deps:
    {{compose}} up -d --wait postgres dex

# run the whole stack in Docker, exactly like the README
stack:
    docker compose up --build

# stop containers (data is kept)
down:
    {{compose}} down

# stop containers and delete the database and uploaded ride files
nuke:
    {{compose}} down -v
    rm -rf .dev/files

# open psql on the dev database
db:
    psql "postgresql://velomine:velomine-dev@localhost:5432/velomine"

# server with hot reload on http://localhost:8080 (same address as the Docker stack, so Dex SSO works)
server: deps
    #!/usr/bin/env bash
    set -euo pipefail
    export ASPNETCORE_URLS=http://localhost:8080
    export Velomine__Admin__Email=admin@velomine.local
    export Velomine__Admin__Password=Velomine-dev-1
    export Velomine__Sso__Authority=http://dex.localhost:5556/dex
    export Velomine__Sso__ClientId=velomine
    export Velomine__Sso__ClientSecret=velomine-dev-secret
    export Velomine__Sso__AppClientId=velomine-app
    export Velomine__Sso__DisplayName="Dex (local test)"
    export Velomine__Sso__AllowInsecureHttp=true
    exec dotnet watch run --project src/Velomine.Server

# build the web app into the server's wwwroot; reload http://localhost:8080 to see it
web:
    cd app && flutter build web --no-web-resources-cdn -o ../src/Velomine.Server/wwwroot

# start the Android emulator
emu:
    flutter emulators --launch {{avd}}

# run the app on the emulator; adb reverse lets it reach the server and local Dex at localhost
android:
    adb reverse tcp:8080 tcp:8080
    adb reverse tcp:5556 tcp:5556
    cd app && flutter run

# add an EF Core migration: just migration AddSomething
migration name:
    dotnet ef migrations add {{name}} --project src/Velomine.Server --output-dir Data/Migrations

# regenerate the Dart API client after changing an endpoint
api-client:
    tools/generate-api-client.sh

# regenerate the Riverpod providers after changing a @riverpod declaration
codegen:
    cd app && dart run build_runner build

# the checks from the README
check:
    dotnet test --solution Velomine.slnx
    cd app && dart run build_runner build && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
