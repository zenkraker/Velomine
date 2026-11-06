namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>One recorded moment. T is seconds since the ride's first sample; null means the file has no value.</summary>
public readonly record struct Sample(
    double T,
    double? Latitude = null,
    double? Longitude = null,
    float? Altitude = null,
    float? Speed = null,
    float? Distance = null,
    short? HeartRate = null,
    short? Power = null,
    short? Cadence = null,
    short? Temperature = null);

/// <summary>A stopped interval in a ride, in seconds relative to the first sample.</summary>
public readonly record struct PauseInterval(double StartS, double EndS)
{
    public double DurationS => Math.Max(0, EndS - StartS);
}

/// <summary>What every file format is turned into. Parsers know nothing about the database.</summary>
public sealed class ParsedRide
{
    public required DateTimeOffset StartTime { get; init; }

    public int? UtcOffsetMinutes { get; init; }

    public string? Device { get; init; }

    /// <summary>Normalized power the recording device worked out itself (FIT sessions), preferred over our own.</summary>
    public int? DeviceNormalizedPowerW { get; init; }

    /// <summary>The device's own elapsed and moving time, when the file has them.</summary>
    public double? DeviceElapsedS { get; init; }

    public double? DeviceMovingS { get; init; }

    /// <summary>Timer stop/start intervals (auto-pause or manual pauses), relative to the first sample.</summary>
    public IReadOnlyList<PauseInterval> Pauses { get; init; } = [];

    public required IReadOnlyList<Sample> Samples { get; init; }
}

/// <summary>A file that cannot be used. Code is a short stable reason such as "corrupt_file" or "not_cycling".</summary>
public sealed class RideParseException(string code, string message) : Exception(message)
{
    public string Code { get; } = code;
}
