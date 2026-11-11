using Microsoft.Extensions.Options;
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
/// The composition root for logs, traces, metrics and errors. Application code only ever sees
/// ILogger, ActivitySource and Meter; Serilog, OpenTelemetry and Sentry stay in this folder.
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
        var version = BuildInfo.Version;
        var environment = builder.Environment.EnvironmentName;

        builder.Services.AddHttpContextAccessor();
        builder.Logging.ClearProviders();
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

            if (telemetry.IsActive)
                configuration.WriteTo.Sentry(o =>
                {
                    // UseSentry below owns the SDK; this sink only forwards Serilog events.
                    o.InitializeSdk = false;
                    o.EnableLogs = true;
                    o.MinimumBreadcrumbLevel = LogEventLevel.Warning;
                    o.MinimumEventLevel = LogEventLevel.Error;
                    o.RestrictedToMinimumLevel = LogEventLevel.Information;
                });
        });

        builder.WebHost.UseSentry(o =>
        {
            o.Dsn = telemetry.IsActive ? telemetry.Sentry.Dsn : string.Empty;
            o.Environment = string.IsNullOrWhiteSpace(telemetry.Sentry.Environment) ? environment : telemetry.Sentry.Environment;
            o.Release = string.IsNullOrWhiteSpace(telemetry.Sentry.Release) ? version : telemetry.Sentry.Release;
            o.SendDefaultPii = false;
            o.EnableLogs = true;
            // Serilog's Sentry sink owns log forwarding. Keep Sentry's own ILogger provider quiet,
            // so a request is not logged twice.
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
            o.SetBeforeSendLog(ScrubLog);
            o.SetBeforeSendMetric(ScrubMetric);
            if (telemetry.IsActive) o.UseOtlp();
        });

        var openTelemetry = builder.Services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService("velomine-server", serviceVersion: version)
                .AddAttributes([new KeyValuePair<string, object>("deployment.environment", environment)]));

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

            if (telemetry.IsActive)
                tracing.AddSentryOtlpExporter(
                    telemetry.Sentry.Dsn!,
                    telemetry.Otlp.Enabled ? new Uri(telemetry.Otlp.Endpoint!) : null);
        });

        if (telemetry.IsActive)
            builder.Services.AddHostedService<SentryMetricsListener>();

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
            {
                diagnosticContext.Set("Tenant", context.Request.Host.Host);
                diagnosticContext.Set(
                    "Route",
                    context.GetEndpoint() is Microsoft.AspNetCore.Routing.RouteEndpoint { RoutePattern.RawText: { } route }
                        ? route
                        : "unmatched");
            };
        });

        return app;
    }

    private static SentryLog? ScrubLog(SentryLog log)
    {
        if (log.TryGetAttribute("user.id", out _) ||
            log.TryGetAttribute("user.name", out _) ||
            log.TryGetAttribute("user.email", out _)) return null;
        log.SetAttribute("server.address", "velomine");
        return log;
    }

    private static SentryMetric? ScrubMetric(SentryMetric metric)
    {
        if (metric.TryGetAttribute<object>("user.id", out _) ||
            metric.TryGetAttribute<object>("user.name", out _) ||
            metric.TryGetAttribute<object>("user.email", out _)) return null;
        metric.SetAttribute("server.address", "velomine");
        return metric;
    }
}
