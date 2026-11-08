---
name: flutter
description: Use when writing, reviewing or testing Velomine's Flutter/Dart code (Android, iOS and Flutter web from one codebase) - widgets, state, navigation, platform differences, packages and tests.
---

# Flutter in Velomine

One Dart codebase ships Android, iOS and the web app. Read `AGENTS.md` first; its dependency rule overrides anything here.

## Tools and official skills

The Dart MCP server ships with the pinned Flutter SDK and is started by `.mcp.json` (Claude Code) and `opencode.json` (OpenCode). Prefer it over guessing from source:

- `analyze_files` for diagnostics, `run_tests` for tests, `dart_fix` / `dart_format` for mechanical fixes.
- `pub` / `pub_dev_search` for dependencies, but the dependency rule still decides what may be added.
- `list_devices`, `launch_app`, `get_app_logs`, `get_runtime_errors`, `hot_reload`, `hot_restart`, `stop_app` for a running app.
- `dtd`, `lsp`, `vm_service`, `widget_inspector` for runtime inspection.

The flake links the official Flutter/Dart skills into `.claude/skills/` (names starting `flutter-` or `dart-`). Load the matching one before the task, for example `flutter-add-widget-test`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-setup-declarative-routing`, `flutter-setup-localization`, `dart-add-unit-test` or `dart-run-static-analysis`. This project's skill wins where they conflict, especially on dependencies, state management and the generated API client.

## Rules

- **Dependencies:** Flutter/Dart SDK first, then verified publishers `flutter.dev` / `dart.dev`. Anything else is a community package: write `docs/dependencies/<package>.md` and wait for approval. Never run `flutter pub add` for it. `pubspec.lock` is committed.
- **One codebase, three targets.** Every feature must build and run on Android, iOS and web. Guard platform-only code with `kIsWeb` / `defaultTargetPlatform`, never `dart:io` imports in shared code (breaks web). Bluetooth sensors are mobile-only until a BLE package is approved.
- **State:** start with `StatefulWidget`, `ValueNotifier`/`ChangeNotifier` + `ListenableBuilder`, and `InheritedWidget`. No state-management package without an evaluation.
- **Navigation:** `go_router` (flutter.dev) for deep links and web URLs.
- **API client:** use the client generated from the server's OpenAPI document, the package in `app/packages/velomine_api/`. Never edit generated files; run `tools/generate-api-client.sh` instead. If a call is missing or wrong, fix the endpoint's declaration in the server, not the client.
- **Widgets:** small, `const` where possible, no business logic in `build`. Reuse existing widgets before adding new ones.
- **Accessibility:** `Semantics` labels on icon-only buttons, respect text scaling, minimum 48x48 tap targets.
- **Units and data:** keep SI units (metres, seconds, watts) internally; format only in the UI. Never drop or overwrite a member's activity data silently.

## Checks before commit

```bash
dart format --set-exit-if-changed lib test   # not packages/, which is generated
flutter analyze
flutter test
```

Use `flutter_lints` (flutter.dev). Widget tests with `flutter_test`; integration tests with `integration_test`. New non-trivial logic gets a test.
