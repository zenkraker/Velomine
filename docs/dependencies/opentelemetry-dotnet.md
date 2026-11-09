# OpenTelemetry .NET 1.20.x and Npgsql.OpenTelemetry 10.0.3

## Need
Vendor-neutral traces and metrics around ASP.NET Core, outbound HTTP, Npgsql and the ride ingestion
pipeline. The instrumentation API is `System.Diagnostics.ActivitySource`/`Meter`, so the backend can
change without touching feature code.

## Alternatives considered
- Sentry's own tracing: fewer packages, but ties instrumentation to one vendor and gives up the OTLP exit.
- Microsoft's built-in metrics + `dotnet-monitor`: good for ad-hoc inspection and still used, but no
  distributed traces or OTLP export from the app.
- Azure Monitor OpenTelemetry: couples the server to one host; the deployment must stay portable.

## Licence
Apache-2.0 for the OpenTelemetry .NET packages; `Npgsql.OpenTelemetry` is published with the already
approved Npgsql provider (PostgreSQL licence).

## Maintenance
- OpenTelemetry .NET 1.20.1/1.20.2, CNCF project, frequent releases.
- `Npgsql.OpenTelemetry` 10.0.3 matches the approved `Npgsql.EntityFrameworkCore.PostgreSQL` 10.0.3 line.

## Security
- The transitive `OpenTelemetry.Exporter.OpenTelemetryProtocol` 1.12.0 pulled by
  `Sentry.OpenTelemetry.Exporter` had a known moderate advisory (GHSA-4625-4j76-fww9). The project pins
  the exporter to 1.20.1 and builds with warnings as errors, which caught it.
- No member data is attached by the instrumentation; `RedactingActivityProcessor` removes raw URLs,
  query strings, headers, IP addresses, user attributes and database statements.
- Sentry's OTLP trace ingestion is in open beta. Accepted 2026-11-09; the fallback is Sentry native
  tracing with no change to `ActivitySource` call sites.

## Platform support
.NET 10. No Flutter dependency; Dart's OTel SDKs are not mature enough for the app, which uses Sentry.

## Size and performance
Small. Sampling starts at 5 % (`Telemetry:TraceSampleRatio`), so the trace volume stays inside the Sentry
Developer/Team quota. Metrics are a small `Meter` set bridged to Sentry by `MeterListener`.

## Risk and exit plan
All instrumentation uses BCL types. Point `AddSentryOtlpExporter` at an OTel Collector or replace it with
`AddOtlpExporter` for Grafana/SigNoz; the feature code does not change. If the beta path misbehaves,
remove the exporter and enable Sentry's `TracesSampleRate` instead.

## Recommendation
Approve with conditions: traces only through OTLP (Sentry does not accept OTLP metrics); metrics go
through `MeterListener` to Sentry; 5–10 % sampling; the redaction processor is mandatory; no raw path,
query string, header, IP, user or ride identifier in any attribute.
