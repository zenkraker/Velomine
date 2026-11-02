# Velomine app

One Flutter codebase for the web app, Android and iOS. The web app is built by the repository's `Dockerfile` and served by the server itself; see the main [README](../README.md) and [docs/architecture.md](../docs/architecture.md).

```
lib/            the app (core/ session, theme and formatting; features/ auth, rides, admin)
packages/       velomine_api, the generated API client: never edit it, run tools/generate-api-client.sh
test/           widget tests; a fake server answers the generated client's calls
```

```
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Run it against a server: `flutter run -d chrome --dart-define=VELOMINE_URL=http://localhost:8080`. The browser build signs in with the session cookie, which only works when the app is served from the server's own address (as in `docker compose`); other builds use bearer tokens.
