namespace Velomine.Server.Observability;

/// <summary>
/// Opt-in telemetry for this deployment, bound from "Velomine:Telemetry". Off unless an operator turns it on and names a
/// destination. Nothing here names a vendor:
/// <list type="bullet">
/// <item>Traces, metrics and logs go over OTLP to whatever the standard OpenTelemetry variables name
/// (<c>OTEL_EXPORTER_OTLP_ENDPOINT</c>, <c>OTEL_EXPORTER_OTLP_HEADERS</c>, <c>OTEL_EXPORTER_OTLP_PROTOCOL</c>).</item>
/// <item>Error reports go to the DSN of any error-tracking service that speaks the common DSN protocol.</item>
/// </list>
/// </summary>
public sealed class TelemetryOptions
{
    /// <summary>The standard OpenTelemetry variable that turns the OTLP export on.</summary>
    public const string OtlpEndpointKey = "OTEL_EXPORTER_OTLP_ENDPOINT";

    public bool Enabled { get; set; }

    /// <summary>Share of traces exported. Errors are always reported.</summary>
    public double TraceSampleRatio { get; set; } = 0.05;

    /// <summary>The deployment name on every signal, for example "demo". Empty: the hosting environment's name.</summary>
    public string? Environment { get; set; }

    public DsnOptions Errors { get; set; } = new();

    public DsnOptions App { get; set; } = new();

    /// <summary>Where the server's error reports go. Empty: none.</summary>
    public string? ErrorsDsn => FirstSet(Errors.Dsn);

    /// <summary>The DSN opted-in apps receive. Falls back to the server's, for a single-project setup.</summary>
    public string? AppDsn => FirstSet(App.Dsn, ErrorsDsn);

    public string? EffectiveEnvironment => FirstSet(Environment);

    public bool IsErrorsActive => Enabled && ErrorsDsn is not null;

    public bool IsAppActive => Enabled && AppDsn is not null;

    private static string? FirstSet(params string?[] values) =>
        values.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v))?.Trim();
}

public sealed class DsnOptions
{
    /// <summary>An error-tracking DSN: https://key@host/project.</summary>
    public string? Dsn { get; set; }
}
