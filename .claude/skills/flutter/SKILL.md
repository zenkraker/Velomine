---
name: flutter
description: Use when writing, reviewing or testing Velomine's Flutter/Dart code (Android, iOS and Flutter web from one codebase) - widgets, state, navigation, platform differences, packages and tests.
---

# Flutter in Velomine

Practical guidance for the app. The rules are in `AGENTS.md` (*App*, *State and events*, *Phone recorder*, *API*, *Tests*): Riverpod with MVVM, `CommandState`, `Result<T>`, `go_router`, the generated API client. Where this skill and `AGENTS.md` disagree, `AGENTS.md` wins.

## Tools

The SDK-bundled Dart MCP server is started by both agents. Prefer it over guessing from source:

- `analyze_files` for diagnostics, `run_tests` for tests, `dart_fix` / `dart_format` for mechanical fixes.
- `pub` / `pub_dev_search` to look at packages; the dependency rule in `AGENTS.md` still decides what may be added.
- `list_devices`, `launch_app`, `get_app_logs`, `get_runtime_errors`, `hot_reload`, `hot_restart`, `stop_app` for a running app.
- `dtd`, `lsp`, `vm_service`, `widget_inspector` for runtime inspection.

Load the matching official Flutter/Dart skill before the task, for example `flutter-add-widget-test`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-setup-localization` or `dart-add-unit-test`. This skill and `AGENTS.md` win where they disagree, especially on dependencies, state management and the generated client.

## Writing code

- **New screen:** a route in `go_router`, a `<Screen>ViewModel` and immutable `<Screen>State`, data through the feature's `<area>_data.dart`. Run `just codegen` after changing a `@riverpod` provider.
- **New string:** add it to both `app_en.arb` and `app_it.arb`.
- **Widgets:** small and `const` where possible; leaf widgets take plain values and callbacks. Reuse existing widgets before adding new ones.
- **Platforms:** check every change builds for web as well as the phone; keep `dart:io` out of shared code.
- **Units:** SI internally (metres, seconds, watts); format only in the view. Never drop or overwrite a member's activity data silently.

## Tests

Widget tests with `flutter_test` against a fake server behind the generated client; ViewModels are tested without `BuildContext`. `integration_test` for flows on a device. Lints come from `flutter_lints` and `riverpod_lint`.

## Before committing

Run `just check`.
