using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public enum RideStatus
{
    /// <summary>Saved, waiting to be (or being) read.</summary>
    Processing,
    Ready,
    /// <summary>The file could not be used; <see cref="Ride.Error"/> says why. The original file is kept.</summary>
    Failed,
    /// <summary>The same ride was already uploaded; hidden from lists. See <see cref="Ride.DuplicateOf"/>.</summary>
    Duplicate,
}

/// <summary>Whether speed came from the file (a sensor or the device) or was worked out from GPS positions.</summary>
public enum SpeedSource
{
    Device,
    Gps,
}

public sealed class Ride
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public RideStatus Status { get; set; }

    /// <summary>A short code such as "corrupt_file" or "not_cycling" when <see cref="Status"/> is Failed.</summary>
    public string? Error { get; set; }

    public Guid? DuplicateOf { get; set; }

    /// <summary>From the Idempotency-Key header; the same key from the same member returns the same ride.</summary>
    public string? IdempotencyKey { get; set; }

    public string FileSha256 { get; set; } = "";

    public string FileName { get; set; } = "";

    /// <summary>Identifies a ride for duplicate checks: the file hash plus the start time.</summary>
    public string? DedupKey { get; set; }

    public DateTimeOffset UploadedAt { get; set; }

    /// <summary>Always UTC.</summary>
    public DateTimeOffset? StartTime { get; set; }

    /// <summary>The local time zone offset at the start, when the file says (FIT does); null otherwise.</summary>
    public int? UtcOffsetMinutes { get; set; }

    public string? Device { get; set; }

    public double? DistanceM { get; set; }

    public double? ElapsedS { get; set; }

    public double? MovingS { get; set; }

    public double? ElevationGainM { get; set; }

    public double? ElevationLossM { get; set; }

    public double? AvgSpeedMs { get; set; }

    public double? MaxSpeedMs { get; set; }

    public SpeedSource? SpeedSource { get; set; }

    public int? AvgPowerW { get; set; }

    public int? MaxPowerW { get; set; }

    public int? NormalizedPowerW { get; set; }

    /// <summary>Normalized power divided by FTP, worked out when the ride was read.</summary>
    public double? IntensityFactor { get; set; }

    /// <summary>Training Stress Score from power, moving time and FTP, worked out when the ride was read.</summary>
    public double? Tss { get; set; }

    /// <summary>Zone-weighted heart-rate load in points: one per minute in Z1, five in Z5.</summary>
    public double? Trimp { get; set; }

    public int? AvgHeartRate { get; set; }

    public int? MaxHeartRate { get; set; }

    public int? AvgCadence { get; set; }

    /// <summary>The bike ridden. Copied from the member's default bike when the ride is imported; the member can change it.</summary>
    public Guid? BikeId { get; set; }

    /// <summary>PostgreSQL's xmin, so two edits of the same ride cannot silently overwrite each other.</summary>
    public uint Version { get; set; }

    public User? Owner { get; set; }

    public RideStreams? Streams { get; set; }

    /// <summary>Best mean maximal power for the durations a power curve shows, worked out when the ride is read.</summary>
    public List<RidePowerBest> PowerBests { get; set; } = [];
}

/// <summary>One duration's best average power on one ride; zero values are not stored.</summary>
public sealed class RidePowerBest
{
    public Guid RideId { get; set; }

    /// <summary>Window length in seconds, one of <see cref="Ingestion.PowerBests.Durations"/>.</summary>
    public int DurationS { get; set; }

    public int Watts { get; set; }
}

/// <summary>
/// The recorded samples of a ride, one array per signal, all the same length and aligned by index.
/// A signal the file does not have is null; a missing value inside a signal is a null element.
/// </summary>
public sealed class RideStreams
{
    public Guid RideId { get; set; }

    /// <summary>Seconds since the ride's start time.</summary>
    public double[] Time { get; set; } = [];

    public double?[]? Latitude { get; set; }

    public double?[]? Longitude { get; set; }

    public float?[]? Altitude { get; set; }

    public float?[]? Speed { get; set; }

    public float?[]? Distance { get; set; }

    public short?[]? HeartRate { get; set; }

    public short?[]? Power { get; set; }

    public short?[]? Cadence { get; set; }

    public short?[]? Temperature { get; set; }
}
