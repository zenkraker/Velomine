namespace Velomine.Server.Observability;

/// <summary>Opt-in telemetry for this deployment. Off unless an operator configures a DSN.</summary>
public sealed class TelemetryOptions
{
    public bool Enabled { get; set; }

    public SentryTelemetryOptions Sentry { get; set; } = new();

    public OtlpTelemetryOptions Otlp { get; set; } = new();

    /// <summary>Share of traces exported. Errors are always sent by Sentry.</summary>
    public double TraceSampleRatio { get; set; } = 0.05;

    public bool IsActive => Enabled && !string.IsNullOrWhiteSpace(Sentry.Dsn);
}

public sealed class SentryTelemetryOptions
{
    public string? Dsn { get; set; }

    public string Environment { get; set; } = "production";

    public string? Release { get; set; }
}

public sealed class OtlpTelemetryOptions
{
    public string? Endpoint { get; set; }

    public bool Enabled => !string.IsNullOrWhiteSpace(Endpoint);
}
