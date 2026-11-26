avd := "velomine"
device := "medium_phone"
image := "system-images;android-36;google_apis_playstore;x86_64"

# Every docker compose command below runs the stack with Dex, the local single sign-on provider.
export COMPOSE_FILE := "docker-compose.yml:compose.development.yaml"

# list commands
default:
    @just --list

# one-time setup: .NET tools and Flutter packages
setup:
    dotnet tool restore
    cd app && flutter pub get

# build and start the whole stack, with Dex, in Docker on http://localhost:8080; run it again after any change
up:
    docker compose up --build -d --wait --remove-orphans

# follow the server's log
logs:
    docker compose logs -f server web

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
# (needs the Android emulator and a system image, which the dev container does not have: use `just phone` there)
emu:
    #!/usr/bin/env bash
    set -euo pipefail
    avdmanager list avd -c | grep -qx {{avd}} || echo no | avdmanager create avd -n {{avd}} -k "{{image}}" -d {{device}}
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
    dotnet tool restore
    dotnet ef migrations add {{name}} --project src/Velomine.Server --output-dir Data/Migrations

# regenerate the Dart API client after changing an endpoint
api-client:
    tools/generate-api-client.sh

# regenerate the Riverpod providers after changing a @riverpod declaration
codegen:
    cd app && dart run build_runner build

# run the Kotlin tests: the FIT encoder and the recorder models
android-test:
    cd app/android && ./gradlew :app:testDebugUnitTest -x compileFlutterBuildDebug

# count the duplicated UI patterns the shared-widget rule keeps down; lower is better
ui-dupes:
    #!/usr/bin/env bash
    set -euo pipefail
    cd app/lib
    count() { printf '%-22s %s\n' "$1" "$(grep -rn "$2" features core --include=*.dart | wc -l)"; }
    count "private widgets" 'class _.*extends \(Stateless\|Stateful\)Widget'
    count "Card(" '\(^\|[^A-Za-z_]\)Card('
    count "TextField(" '\(^\|[^A-Za-z_]\)TextField(\|TextFormField('
    count "showSnackBar" 'showSnackBar'
    count "SegmentedButton" 'SegmentedButton'
    count "TextStyle(" 'TextStyle('
    count "Color(0x" 'Color(0x'
    count "EdgeInsets.all(n)" 'EdgeInsets.all([0-9]'
    count "SizedBox(height: n)" 'SizedBox(height: [0-9]'
    count "SizedBox(width: n)" 'SizedBox(width: [0-9]'
    count "spacing: n" 'spacing: [0-9]'

# the duplicate counts as a budget: a count may fall, never rise (`docs/design/audit-2026-11-25.md`, S4/S8)
ui-dupes-check:
    #!/usr/bin/env bash
    set -euo pipefail
    cd app/lib
    baseline=../../tools/ui-dupes.baseline
    [ -f "$baseline" ] || { echo "missing $baseline: run 'just ui-dupes > tools/ui-dupes.baseline'"; exit 1; }
    fail=0
    lower=0
    count() {
      local name="$1" now
      # A pattern the code no longer has makes grep exit 1; under `pipefail` that would abort the script.
      now=$(grep -rn "$2" features core --include=*.dart | wc -l || true)
      local was
      # The name may hold spaces and brackets, so compare it as text, not as a pattern.
      was=$(awk -v n="$name" '{ line=$0; value=$NF; sub(/[ \t]+[0-9]+$/, "", line); sub(/[ \t]+$/, "", line); if (line == n) print value }' "$baseline")
      [ -n "$was" ] || { echo "  $name: not in the baseline"; fail=1; return; }
      if [ "$now" -gt "$was" ]; then
        echo "  $name: $was -> $now  (raised)"; fail=1
      elif [ "$now" -lt "$was" ]; then
        echo "  $name: $was -> $now  (lower: take the new number into the baseline)"; lower=1
      fi
    }
    count "private widgets" 'class _.*extends \(Stateless\|Stateful\)Widget'
    count "Card(" '\(^\|[^A-Za-z_]\)Card('
    count "TextField(" '\(^\|[^A-Za-z_]\)TextField(\|TextFormField('
    count "showSnackBar" 'showSnackBar'
    count "SegmentedButton" 'SegmentedButton'
    count "TextStyle(" 'TextStyle('
    count "Color(0x" 'Color(0x'
    count "EdgeInsets.all(n)" 'EdgeInsets.all([0-9]'
    count "SizedBox(height: n)" 'SizedBox(height: [0-9]'
    count "SizedBox(width: n)" 'SizedBox(width: [0-9]'
    count "spacing: n" 'spacing: [0-9]'
    if [ "$fail" = 1 ]; then
      echo "ui-dupes: a duplicate pattern grew. Use the shared widget instead."
      exit 1
    fi
    if [ "$lower" = 1 ]; then echo "ui-dupes: no pattern grew, and one fell."; fi
    exit 0

# every check to run before a commit
check:
    @just check-server
    @just ui-dupes-check
    cd app && dart run build_runner build && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
    cd app/android && ./gradlew :app:testDebugUnitTest -x compileFlutterBuildDebug

# the server half of `check`: enough for a change that touches no file under app/
check-server:
    dotnet format Velomine.slnx --verify-no-changes
    dotnet test --solution Velomine.slnx
