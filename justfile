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

# build and start the whole stack in Docker on http://localhost:8080; run it again after any change
up:
    docker compose up --build -d --wait

# follow the server's log
logs:
    docker compose logs -f velomine

# stop containers (data is kept)
down:
    docker compose down

# stop containers and delete the database, ride files and keys
nuke:
    docker compose down -v

# open psql on the database inside the postgres container
db:
    docker compose exec postgres psql -U velomine velomine

# run the app on the Android emulator: starts it if needed, then hot-reloads against the stack from `just up`
emu:
    #!/usr/bin/env bash
    set -euo pipefail
    device=$(adb devices | awk '/^emulator-/ {print $1; exit}')
    if [ -z "$device" ]; then
      flutter emulators --launch {{avd}}
      until device=$(adb devices | awk '/^emulator-/ {print $1; exit}') && [ -n "$device" ] \
        && [ "$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
    fi
    adb -s "$device" reverse tcp:8080 tcp:8080
    adb -s "$device" reverse tcp:5556 tcp:5556
    cd app && flutter run -d "$device"

# run the app on a phone over Wi-Fi adb: `just phone 192.168.1.20:5555`, or `just phone` if it is already connected
phone address="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "{{address}}" ]; then adb connect "{{address}}"; fi
    device="{{address}}"
    [ -n "$device" ] || device=$(adb devices | awk 'NR > 1 && $2 == "device" && $1 !~ /^emulator-/ {print $1; exit}')
    [ -n "$device" ] || { echo "No phone connected. Pair it with Wireless debugging, then run: just phone <ip:port>"; exit 1; }
    adb -s "$device" reverse tcp:8080 tcp:8080
    adb -s "$device" reverse tcp:5556 tcp:5556
    cd app && flutter run -d "$device"

# add an EF Core migration: just migration AddSomething
migration name:
    dotnet ef migrations add {{name}} --project src/Velomine.Server --output-dir Data/Migrations

# regenerate the Dart API client after changing an endpoint
api-client:
    tools/generate-api-client.sh

# regenerate the Riverpod providers after changing a @riverpod declaration
codegen:
    cd app && dart run build_runner build

# every check to run before a commit
check:
    dotnet format Velomine.slnx --verify-no-changes
    dotnet test --solution Velomine.slnx
    cd app && dart run build_runner build && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
