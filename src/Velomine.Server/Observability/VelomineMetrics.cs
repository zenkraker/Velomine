using System.Diagnostics.Metrics;

namespace Velomine.Server.Observability;

/// <summary>
/// The small set of business and background-job measurements that a trace or an error cannot derive.
/// Application code uses these System.Diagnostics.Metrics instruments; TelemetrySetup exports them over OTLP when telemetry is on.
/// </summary>
public static class VelomineMetrics
{
    public static readonly Meter Meter = new("Velomine", "1.0");

    public static readonly Counter<long> RidesIngested =
        Meter.CreateCounter<long>("rides_ingested", description: "Rides that finished ingestion.");

    public static readonly Histogram<double> RideIngestionDuration =
        Meter.CreateHistogram<double>("ride_ingestion_duration", unit: "ms", description: "Time to parse and store one ride.");

    public static readonly Counter<long> UploadFailures =
        Meter.CreateCounter<long>("ride_upload_failures", description: "Uploads rejected or failed, by reason.");

    public static readonly Counter<long> CheckInsSaved =
        Meter.CreateCounter<long>("check_ins_saved", description: "Daily wellbeing check-ins saved.");
}
