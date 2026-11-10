# Serilog 10.0.0 / 6.1.1 / 10.0.1

## Need
Structured logs with routing to more than one destination without touching feature code. The Microsoft
`ILogger` abstraction is kept everywhere; Serilog is only the provider at the composition root.

## Alternatives considered
- Built-in `Microsoft.Extensions.Logging` JSON console and the OpenTelemetry logging provider: fewer
  packages and enough for one destination. Rejected because the owner wants to add or swap a sink
  (Sentry now, OTLP/Seq/Loki later) without code changes.
- NLog/log4net: older and no advantage here.

## Licence
Apache-2.0.

## Maintenance
- `Serilog.AspNetCore` 10.0.0 tracks the .NET 10 hosting package; `Serilog.Sinks.Console` 6.1.1;
  `Serilog.Settings.Configuration` 10.0.1.
- Actively maintained under the Serilog organisation, with frequent releases.

## Security
- No known advisories at evaluation.
- Transitive dependencies: `Serilog`, `Microsoft.Extensions.DependencyModel` and the hosting
  abstractions. No native code.
- The risk is log content, not the package: `ForbiddenPropertiesEnricher` removes identifiers, and the
  request middleware logs route templates instead of raw paths.

## Platform support
.NET 10. No Flutter dependency.

## Size and performance
Small. Startup cost is one logger pipeline. Source-generated `LoggerMessage` methods keep hot-path
logging allocation-free.

## Risk and exit plan
`Features/**` and `Data/**` depend only on `ILogger<T>`. Removing Serilog means changing `Program.cs` and
`Observability/` back to the built-in console/OpenTelemetry providers; no slice changes.

## Recommendation
Approve with conditions: Serilog types stay in `Observability/` and the composition root; application code
uses `ILogger<T>` only; the console and Sentry sinks are enabled; no member data in any property.
