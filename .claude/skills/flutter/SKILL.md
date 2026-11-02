---
name: flutter
description: Use when writing, reviewing or testing Velomine's Flutter/Dart code (Android, iOS and Flutter web from one codebase) - widgets, state, navigation, platform differences, packages and tests.
---

# Flutter in Velomine

One Dart codebase ships Android, iOS and the web app. Read `CLAUDE.md` first; its dependency rule overrides anything here.

## Rules

- **Dependencies:** Flutter/Dart SDK first, then verified publishers `flutter.dev` / `dart.dev`. Anything else is a community package: write `docs/dependencies/<package>.md` and wait for approval. Never run `flutter pub add` for it. `pubspec.lock` is committed.
- **One codebase, three targets.** Every feature must build and run on Android, iOS and web. Guard platform-only code with `kIsWeb` / `defaultTargetPlatform`, never `dart:io` imports in shared code (breaks web). Bluetooth sensors are mobile-only until a BLE package is approved.
- **State:** start with `StatefulWidget`, `ValueNotifier`/`ChangeNotifier` + `ListenableBuilder`, and `InheritedWidget`. No state-management package without an evaluation.
- **Navigation:** `go_router` (flutter.dev) for deep links and web URLs.
- **API client:** use the client generated from the server's OpenAPI document in `lib/core/api/generated/`. Never edit generated files; regenerate them instead.
- **Widgets:** small, `const` where possible, no business logic in `build`. Reuse existing widgets before adding new ones.
- **Accessibility:** `Semantics` labels on icon-only buttons, respect text scaling, minimum 48x48 tap targets.
- **Units and data:** keep SI units (metres, seconds, watts) internally; format only in the UI. Never drop or overwrite a member's activity data silently.

## Checks before commit

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Use `flutter_lints` (flutter.dev). Widget tests with `flutter_test`; integration tests with `integration_test`. New non-trivial logic gets a test.
