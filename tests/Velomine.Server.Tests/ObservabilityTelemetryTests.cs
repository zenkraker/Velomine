using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Logs;
using Serilog.Events;
using Serilog.Parsing;
using Velomine.Server.Observability;

namespace Velomine.Server.Tests;

public sealed class ObservabilityTelemetryTests
{
    [Fact]
    public void RedactingActivityProcessor_ShouldRemoveTheRawPathAndUseTheRoute_WhenActivityEnds()
    {
        using var source = new ActivitySource("test");
        using var listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
        };
        ActivitySource.AddActivityListener(listener);
        using var activity = source.StartActivity("test", ActivityKind.Server)!;
        activity.SetTag("url.path", "/share/secret-token");
        activity.SetTag("url.query", "token=secret");
        activity.SetTag("http.route", "/share/{token}");
        activity.SetTag("http.method", "GET");
        activity.SetTag("user.email", "rider@example.com");

        new RedactingActivityProcessor().OnEnd(activity);

        Assert.Null(activity.GetTagItem("url.path"));
        Assert.Null(activity.GetTagItem("url.query"));
        Assert.Null(activity.GetTagItem("user.email"));
        Assert.Equal("GET /share/{token}", activity.DisplayName);
    }

    [Fact]
    public void ForbiddenPropertiesEnricher_ShouldDropIdentifiers_WhenLogEventCarriesThem()
    {
        var logEvent = new LogEvent(
            DateTimeOffset.UtcNow,
            LogEventLevel.Information,
            null,
            new MessageTemplateParser().Parse("Ride {RideId} for {Email}"),
            [
                new LogEventProperty("RideId", new ScalarValue("ride-1")),
                new LogEventProperty("Email", new ScalarValue("rider@example.com")),
                new LogEventProperty("Route", new ScalarValue("/rides")),
            ]);

        new ForbiddenPropertiesEnricher().Enrich(logEvent, null!);

        Assert.False(logEvent.Properties.ContainsKey("RideId"));
        Assert.False(logEvent.Properties.ContainsKey("Email"));
        Assert.True(logEvent.Properties.ContainsKey("Route"));
    }

    [Fact]
    public void TelemetryOptions_ShouldGiveTheAppTheServerDsn_WhenNoAppDsnIsSet()
    {
        var options = Bind(new()
        {
            ["Enabled"] = "true",
            ["Environment"] = "demo",
            ["Errors:Dsn"] = "https://key@errors.example/1",
        });

        Assert.Equal("https://key@errors.example/1", options.ErrorsDsn);
        Assert.Equal("https://key@errors.example/1", options.AppDsn);
        Assert.Equal("demo", options.EffectiveEnvironment);
        Assert.True(options.IsErrorsActive);
        Assert.True(options.IsAppActive);
    }

    [Fact]
    public void TelemetryOptions_ShouldUseTheAppDsn_WhenBothAreSet()
    {
        var options = Bind(new()
        {
            ["Enabled"] = "true",
            ["Errors:Dsn"] = "https://key@errors.example/1",
            ["App:Dsn"] = "https://key@app.example/2",
        });

        Assert.Equal("https://key@app.example/2", options.AppDsn);
    }

    [Fact]
    public void TelemetryOptions_ShouldStayOff_WhenADsnIsSetButTelemetryIsNotEnabled()
    {
        var options = Bind(new() { ["Errors:Dsn"] = "https://key@errors.example/1" });

        Assert.False(options.IsErrorsActive);
        Assert.False(options.IsAppActive);
    }

    [Fact]
    public void RedactingLogProcessor_ShouldDropPersonalAttributes_WhenALogRecordCarriesThem()
    {
        var exported = new List<List<string>>();
        using var factory = LoggerFactory.Create(logging => logging.AddOpenTelemetry(o =>
        {
            o.AddProcessor(new RedactingLogProcessor());
            o.AddProcessor(new SimpleLogRecordExportProcessor(new CapturingExporter(exported)));
        }));

        factory.CreateLogger("test").LogInformation(
            "Request from {client.address} by {user.email} on {Route}", "203.0.113.7", "rider@example.com", "/rides");

        var keys = exported.Single();
        Assert.DoesNotContain("client.address", keys);
        Assert.DoesNotContain("user.email", keys);
        Assert.Contains("Route", keys);
    }

    private static TelemetryOptions Bind(Dictionary<string, string?> values) =>
        new ConfigurationBuilder().AddInMemoryCollection(values).Build().Get<TelemetryOptions>()!;

    // Records are pooled and reused after export, so the keys are copied while the record is still ours.
    private sealed class CapturingExporter(List<List<string>> exported) : BaseExporter<LogRecord>
    {
        public override ExportResult Export(in Batch<LogRecord> batch)
        {
            foreach (var record in batch) exported.Add([.. record.Attributes?.Select(a => a.Key) ?? []]);
            return ExportResult.Success;
        }
    }
}
