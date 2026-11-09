using System.Diagnostics;
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
}
