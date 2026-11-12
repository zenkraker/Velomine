using OpenTelemetry;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Npgsql;
using Sentry;
using Sentry.Extensibility;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;

namespace Velomine.Server.Observability;

/// <summary>
/// The composition root for logs, traces, metrics and errors. Application code only ever sees ILogger, ActivitySource
/// and Meter; Serilog, OpenTelemetry and the error-reporting SDK stay in this folder.
///
/// Logs always go to the console. With telemetry on, traces, metrics and logs also go over OTLP to the address in the
/// standard OpenTelemetry variables (any OTLP backend), and errors go to an error-tracking DSN. Each destination is optional; a self-hosted server with neither sends nothing.
/// </summary>
public static class TelemetrySetup
{
    public static WebApplicationBuilder AddVelomineTelemetry(this WebApplicationBuilder builder)
    {
        builder.Services.AddOptions<TelemetryOptions>()
            .BindConfiguration("Velomine:Telemetry")
            .Validate(o => o.TraceSampleRatio is >= 0 and <= 1, "Velomine:Telemetry:TraceSampleRatio must be in [0, 1].")
            .ValidateOnStart();

        var telemetry = builder.Configuration.GetSection("Velomine:Telemetry").Get<TelemetryOptions>() ?? new();
        // The OTLP exporter reads its address, headers and protocol from the standard variables itself; this only
        // decides whether to export at all, so a stray OTEL_* variable never turns telemetry on.
        var otlp = telemetry.Enabled && !string.IsNullOrWhiteSpace(builder.Configuration[TelemetryOptions.OtlpEndpointKey]);
        var errors = telemetry.IsErrorsActive;
        var version = BuildInfo.Version;
        var environment = telemetry.EffectiveEnvironment ?? builder.Environment.EnvironmentName;

        builder.Services.AddHttpContextAccessor();
        builder.Logging.ClearProviders();
        // writeToProviders hands Serilog's events, after the enrichers below, to the OpenTelemetry logger provider.
        builder.Services.AddSerilog((services, configuration) =>
        {
            configuration
                .ReadFrom.Configuration(builder.Configuration)
                .ReadFrom.Services(services)
                .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
                .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Warning)
                .MinimumLevel.Override("System.Net.Http", LogEventLevel.Warning)
                .Enrich.FromLogContext()
                .Enrich.With(new RequestContextEnricher(services.GetRequiredService<IHttpContextAccessor>()))
                .Enrich.With<ForbiddenPropertiesEnricher>();

            if (builder.Environment.IsDevelopment())
                configuration.WriteTo.Console();
            else
                configuration.WriteTo.Console(new CompactJsonFormatter());

            if (errors)
                configuration.WriteTo.Sentry(o =>
                {
                    // UseSentry below owns the SDK; this sink only turns error logs into error reports, with the
                    // warnings before them as breadcrumbs. Logs themselves go over OTLP, not here.
                    o.InitializeSdk = false;
                    o.MinimumBreadcrumbLevel = LogEventLevel.Warning;
                    o.MinimumEventLevel = LogEventLevel.Error;
                });
        }, writeToProviders: otlp);

        // Error reports to the error-tracking DSN. An empty DSN leaves the SDK off.
        builder.WebHost.UseSentry(o =>
        {
            o.Dsn = errors ? telemetry.ErrorsDsn : string.Empty;
            o.Environment = environment;
            o.Release = version;
            o.SendDefaultPii = false;
            // Serilog's sink above owns error reports from logs. Keep the SDK's own ILogger provider quiet, so an error
            // is not reported twice.
            o.MinimumBreadcrumbLevel = Microsoft.Extensions.Logging.LogLevel.None;
            o.MinimumEventLevel = Microsoft.Extensions.Logging.LogLevel.None;
            o.MaxRequestBodySize = RequestSize.None;
            o.CaptureFailedRequests = false;
            o.ServerName = "velomine";
            o.AutoSessionTracking = false;
            o.SetBeforeSend((@event, _) =>
            {
                @event.Request = null!;
                @event.User = null!;
                return @event;
            });
        });

        var openTelemetry = builder.Services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService("velomine-server", serviceVersion: version)
                .AddAttributes([new KeyValuePair<string, object>("deployment.environment.name", environment)]));

        // Traces are always collected, so log lines carry trace ids; they leave the process only with OTLP on.
        openTelemetry.WithTracing(tracing =>
        {
            tracing
                .SetSampler(new ParentBasedSampler(new TraceIdRatioBasedSampler(telemetry.TraceSampleRatio)))
                .AddSource("Velomine")
                .AddAspNetCoreInstrumentation(o =>
                {
                    o.RecordException = true;
                    o.Filter = context => context.Request.Path != "/health";
                })
                .AddHttpClientInstrumentation(o => o.RecordException = true)
                .AddNpgsql()
                .AddProcessor(new RedactingActivityProcessor());

            if (otlp) tracing.AddOtlpExporter();
        });

        if (otlp)
        {
            openTelemetry.WithMetrics(metrics => metrics
                .AddMeter(VelomineMetrics.Meter.Name)
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddRuntimeInstrumentation()
                .AddOtlpExporter());

            openTelemetry.WithLogging(
                logging => logging
                    .AddProcessor(new RedactingLogProcessor())
                    .AddOtlpExporter(),
                options =>
                {
                    options.IncludeFormattedMessage = true;
                    options.IncludeScopes = false;
                });
        }

        return builder;
    }

    public static WebApplication UseVelomineTelemetry(this WebApplication app)
    {
        app.UseSerilogRequestLogging(options =>
        {
            options.MessageTemplate = "HTTP {RequestMethod} {Route} responded {StatusCode} in {Elapsed:0.0000} ms";
            options.GetLevel = (context, _, exception) =>
                context.Request.Path == "/health"
                    ? LogEventLevel.Verbose
                    : exception is not null || context.Response.StatusCode >= 500
                        ? LogEventLevel.Error
                        : context.Response.StatusCode >= 400
                            ? LogEventLevel.Warning
                            : LogEventLevel.Information;
            options.EnrichDiagnosticContext = (diagnosticContext, context) =>
                diagnosticContext.Set(
                    "Route",
                    context.GetEndpoint() is Microsoft.AspNetCore.Routing.RouteEndpoint { RoutePattern.RawText: { } route }
                        ? route
                        : "unmatched");
        });

        return app;
    }
}
