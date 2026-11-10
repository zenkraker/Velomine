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

# start the Android emulator
emu:
    flutter emulators --launch {{avd}}

# run the app on the emulator against the stack from `just up`; adb reverse lets it reach the server and Dex at localhost
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

# every check to run before a commit
check:
    dotnet format Velomine.slnx --verify-no-changes
    dotnet test --solution Velomine.slnx
    cd app && dart run build_runner build && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
