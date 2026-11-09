# Sentry .NET and Flutter SDKs 6.12.1 / 10.3.0

## Need
Group errors and crashes with readable stack traces, link them to a trace and the release that introduced
them, and keep the operational cost low for a solo developer. The built-in ASP.NET Core logs and
`dotnet-monitor` cover server diagnostics, but neither groups exceptions nor stores Flutter crash reports.
A managed error tracker is the smallest complete answer.

## Alternatives considered
- Built-in `ILogger` + OpenTelemetry backend: works for server traces/logs, but no Flutter crash
  symbolication and no issue grouping/alerting out of the box.
- GlitchTip or Bugsink (self-hosted, Sentry-compatible): same DSN protocol, but another service to run.
  Kept as the exit path, not the starting point.
- Firebase Crashlytics: mobile only, Firebase account and Google SDK; does not cover the .NET server.
- Self-hosted Sentry: too much operational work at this scale.

## Licence
MIT for `sentry-dotnet` and `sentry-dart`. Sentry Cloud is a paid service under Sentry's terms and DPA;
the free Developer plan is enough at current volume.

## Maintenance
- Last release: 6.12.1 (.NET) and 10.3.0 (Flutter), both 2026.
- Active maintainers and regular releases; `sentry_flutter` is published by the verified `sentry.io`
  publisher on pub.dev.
- Large issue trackers, but official Sentry engineers answer the SDK repositories.

## Security
- No open advisories were known at evaluation; check GitHub advisories before each major update.
- Sentry Cloud processes data as a processor. Use the EU region where required and keep the DSN in
  configuration.
- Transitive dependencies: `Sentry` for both SDKs; the Flutter package brings `ffi`, `http`, `jni`,
  `package_info_plus` and `web`.
- The OTLP ingestion path used by `Sentry.OpenTelemetry.Exporter` is in open beta. Accepted 2026-11-09,
  with Sentry native tracing as the fallback.

## Platform support
- .NET 8+; the server targets .NET 10.
- Flutter Android, iOS and web. `sentry_flutter` 10 requires Android API 26, iOS 15 and Swift Package
  Manager (no CocoaPods).

## Size and performance
Small startup cost on the server. The Flutter SDK adds native crash handlers; tracing is sampled at 5 %
and session replay is off. The Developer plan allows 5k errors, 5M spans and 5 GB of logs/metrics per
month, which is above current volume.

## Risk and exit plan
The SDKs are MIT and the DSN is portable. Point the same DSN at GlitchTip/Bugsink, or move traces to any
OTLP backend; remove the packages and the `Observability/` wiring. No member data is in the payload, so
there is no vendor-side deletion problem.

## Recommendation
Approve with conditions: member contribution is opt-in and off by default; `SendDefaultPii = false`; no
session replay; request bodies, headers, cookies, query strings, raw paths, ride data and health data are
never sent; the server sets a fixed name; self-host has no DSN. Read-only Sentry MCP access is allowed,
never project writes without the owner's approval.
