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

    /// <summary>The DSN the app receives. Falls back to the server DSN for a single-project setup.</summary>
    public string? EffectiveAppDsn =>
        string.IsNullOrWhiteSpace(Sentry.AppDsn) ? Sentry.Dsn : Sentry.AppDsn;

    public bool IsAppActive => Enabled && !string.IsNullOrWhiteSpace(EffectiveAppDsn);
}

public sealed class SentryTelemetryOptions
{
    /// <summary>The server project DSN. Empty leaves server telemetry off.</summary>
    public string? Dsn { get; set; }

    /// <summary>The Flutter app project DSN. Empty falls back to <see cref="Dsn"/>.</summary>
    public string? AppDsn { get; set; }

    public string Environment { get; set; } = "production";

    public string? Release { get; set; }
}

public sealed class OtlpTelemetryOptions
{
    public string? Endpoint { get; set; }

    public bool Enabled => !string.IsNullOrWhiteSpace(Endpoint);
}
