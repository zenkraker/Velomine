# Riverpod 3.5.0

## Need

The Flutter app needs one owner for state that is shared between screens: the signed-in session, the member's club, notifications, the upload queue, and every screen's ViewModel. The Flutter SDK offers `ChangeNotifier` and `InheritedWidget`, but neither provides scope, automatic disposal, dependency injection, or a compile-checked way to reach state from outside the widget tree. The app currently threads controllers through constructors by hand, which is where the sign-out leak and the "screen calls another screen's controller" bugs came from.

Riverpod is the state-management library chosen by the owner. The Flutter architecture guide names it as one of the supported options and the official Compass sample uses the same MVVM shape with `provider`; Riverpod provides the same roles with compile-time providers, auto-dispose and families for route-scoped ViewModels.

## Alternatives considered

- **Flutter SDK primitives (`ChangeNotifier` + `ListenableBuilder`)** — what the app uses today. No scope or disposal, manual wiring, no compile-time provider graph. This is the state the migration replaces.
- **`provider`** — recommended by the Flutter team for dependency injection, and enough for DI, but it does not solve state lifetime, auto-dispose, families or compile-checked access. `provider` remains an acceptable companion for DI; it is not needed once Riverpod is in place.
- **`flutter_bloc`** — a strict event/state pattern; more ceremony than this app needs, and the team already chose Riverpod.
- **`signals`** — smaller ecosystem, no dependency injection story.
- **Writing it ourselves** — a scoped inherited notifier with auto-dispose and families is a framework; months of work to reach parity.

## Licence

MIT. Compatible with Velomine's licence.

## Maintenance

- Last release date: `flutter_riverpod` 3.5.0, 6 November 2026; `riverpod_annotation` 4.0.8 and `riverpod_generator` 4.0.10, same day; `riverpod_lint` 3.2.0, same day.
- Commit activity in the last 12 months: continuous; the 3.0 line shipped in September 2025 and has had regular minor releases since.
- Number of active maintainers: one primary maintainer (Remi Rousselet) with community contributions.
- Open issues and pull requests: triaged on GitHub (`rrousselGit/riverpod`); the issue tracker is active.

The publisher is an unverified uploader on pub.dev, which is why this is a community dependency and needs this record.

## Security

- Known advisories or CVEs: none listed on pub.dev or GitHub advisories at the time of writing.
- Transitive dependencies it brings in:
  - runtime: `riverpod`, `meta` (and Flutter itself);
  - development only: `build_runner`, `riverpod_generator`, `analyzer`, `analyzer_buffer`, `build`, `build_config`, `collection`, `crypto`, `path`, `source_gen`, `source_span`, `yaml`, `riverpod_analyzer_utils`, `analysis_server_plugin`, `analyzer_plugin`.

No telemetry, no network access, no native code.

## Platform support

Dart and Flutter on Android, iOS, web, macOS, Windows and Linux. The package is pure Dart; the code generator runs at build time.

## Size and performance

The runtime is a small Dart package (providers, containers and notifiers) with no assets or native libraries. Code generation runs only during development and CI; the generated `.g.dart` files are committed. Provider container overhead is negligible next to widget rebuilds, and `select` keeps rebuilds narrower than the current `Listenable.merge` wiring.

## Risk and exit plan

Two risks: a single-maintainer project, and frequent minor releases that bring migration notes (3.0 changed life-cycle behaviour). Both are mitigated by keeping the architecture independent of the library: ViewModels are plain classes, state classes are hand-written, and data sources return plain `Result<T>`. Replacing Riverpod would mean rewriting provider declarations and `ref.watch` call sites, not the app's logic. Pin the 3.5 line and read the changelog before a minor update.

## Recommendation

Approve with conditions:

- state management only; no `freezed`, no second state-management library;
- `riverpod_annotation`/`riverpod_generator` for provider declarations, generated files committed;
- `riverpod_lint` enabled through `analysis_options.yaml` (Dart's analyzer plugin mechanism);
- hand-written immutable state classes, so no other code generator is introduced;
- patch and minor updates allowed with the changelog read; a major update is re-evaluated.
