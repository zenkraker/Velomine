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

On Android, the Record tab records GPS rides in a foreground service, saves the raw samples and a FIT file on the phone, uploads finished rides to the server with a retryable queue, and lists them locally. Uploads also run through a WorkManager worker while the app is closed. The recorder auto-pauses after three seconds at or below 0.1 km/h and resumes above it; the switch above the Start button turns that off.

Recorder diagnostics are on in debug builds: native code logs under the `VelomineRecorder` tag and Dart adds the same prefix to `flutter` logs. Follow a manual test with `adb logcat -s VelomineRecorder flutter`.

Run it against a server: `flutter run -d chrome --dart-define=VELOMINE_URL=http://localhost:8080`. The browser build signs in with the session cookie, which only works when the app is served from the server's own address (as in `docker compose`). On a phone, the first screen asks for the server address; `--dart-define=VELOMINE_URL=...` only pre-fills a development build. The phone keeps the refresh token in Android Keystore or the iOS Keychain, so the session survives a restart; the access token stays in memory.
