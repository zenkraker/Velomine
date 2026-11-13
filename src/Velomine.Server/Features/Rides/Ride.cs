using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Privacy;

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

    /// <summary>The import that brought this ride in, or null when the member uploaded it directly.</summary>
    public Guid? ImportId { get; set; }

    /// <summary>
    /// Set for a file that came in a bulk drop (a whole folder at once): the member is told how it went once, in the
    /// summary on screen, not with a notification per file.
    /// </summary>
    public bool Quiet { get; set; }

    /// <summary>Whether reading this ride tells the member with a notification of its own.</summary>
    public bool NotifiesMember => ImportId is null && !Quiet;

    /// <summary>Another app this ride came from, such as "strava"; null when it was recorded here or uploaded by hand.</summary>
    public string? Source { get; set; }

    /// <summary>The ride's id in that app, so importing the same activity again is recognised.</summary>
    public string? SourceId { get; set; }

    public DateTimeOffset UploadedAt { get; set; }

    /// <summary>When the startup backfill finished with this ride; null only for old rides it has not reached yet.</summary>
    public DateTimeOffset? PowerBestsBackfilledAt { get; set; }

    /// <summary>
    /// The <see cref="Ingestion.RideParserVersion.Current"/> this ride was last read with. A ride below the current
    /// version is read again from its original file in the background (see RideReparseService).
    /// </summary>
    public int ParserVersion { get; set; } = Ingestion.RideParserVersion.Current;

    /// <summary>The parser version at which reading this ride again failed, so it is not tried again until the version changes.</summary>
    public int? ReparseFailedVersion { get; set; }

    /// <summary>
    /// The FTP the training load was worked out from when the ride was first read; 0 means the member had none, null
    /// means it was not recorded (rides read before this existed). A re-read uses it, never today's FTP.
    /// </summary>
    public int? LoadFtpW { get; set; }

    /// <summary>The maximum heart rate behind the heart-rate load, recorded like <see cref="LoadFtpW"/>.</summary>
    public int? LoadMaxHeartRate { get; set; }

    /// <summary>Always UTC.</summary>
    public DateTimeOffset? StartTime { get; set; }

    /// <summary>The local time zone offset at the start, when the file says (FIT does); null otherwise.</summary>
    public int? UtcOffsetMinutes { get; set; }

    public string? Device { get; set; }

    /// <summary>The member's own name for the ride, up to <see cref="RideText.MaxTitle"/> characters; null when none was given.</summary>
    public string? Title { get; set; }

    /// <summary>The member's own words about the ride, up to <see cref="RideText.MaxDescription"/> characters; null when none.</summary>
    public string? Description { get; set; }

    /// <summary>road, gravel, mountain or track; null when the file and the member have not said.</summary>
    public string? Discipline { get; set; }

    /// <summary>none or ebike; null when unknown.</summary>
    public string? Assist { get; set; }

    /// <summary>outdoor, indoor or virtual; null when unknown.</summary>
    public string? Environment { get; set; }

    /// <summary>True for a commute; null when not stated.</summary>
    public bool? Commute { get; set; }

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

    /// <summary>
    /// <see cref="PrivacySettings.HideHeartRate"/> at import.
    /// </summary>
    public bool? HideHeartRate { get; set; }

    /// <summary><see cref="PrivacySettings.HidePower"/> at import.</summary>
    public bool? HidePower { get; set; }

    /// <summary><see cref="PrivacySettings.HideCadence"/> at import.</summary>
    public bool? HideCadence { get; set; }

    /// <summary><see cref="PrivacySettings.HideSpeed"/> at import.</summary>
    public bool? HideSpeed { get; set; }

    /// <summary><see cref="PrivacySettings.HideElevation"/> at import.</summary>
    public bool? HideElevation { get; set; }

    /// <summary><see cref="PrivacySettings.HideTemperature"/> at import.</summary>
    public bool? HideTemperature { get; set; }

    /// <summary><see cref="PrivacySettings.TrimStartM"/> at import.</summary>
    public int? TrimStartM { get; set; }

    /// <summary><see cref="PrivacySettings.TrimEndM"/> at import.</summary>
    public int? TrimEndM { get; set; }

    /// <summary>
    /// The member's privacy defaults copied onto the ride when it was imported, so changing a default never changes
    /// what a viewer sees of this ride. Null on a ride imported before the copy existed; the view then uses the
    /// member's current choices. Zones are not part of it: they are places, and their current radius always applies.
    /// A re-read of the ride from its original file keeps it (RideReparseService assigns only what it derives).
    /// </summary>
    public PrivacyDefaults? Privacy
    {
        get => HideHeartRate is null
            ? null
            : new(HideHeartRate.Value, HidePower!.Value, HideCadence!.Value, HideSpeed!.Value,
                HideElevation!.Value, HideTemperature!.Value, TrimStartM!.Value, TrimEndM!.Value);
        set
        {
            HideHeartRate = value?.HideHeartRate;
            HidePower = value?.HidePower;
            HideCadence = value?.HideCadence;
            HideSpeed = value?.HideSpeed;
            HideElevation = value?.HideElevation;
            HideTemperature = value?.HideTemperature;
            TrimStartM = value?.TrimStartM;
            TrimEndM = value?.TrimEndM;
        }
    }

    /// <summary>PostgreSQL's xmin, so two edits of the same ride cannot silently overwrite each other.</summary>
    public uint Version { get; set; }

    public User? Owner { get; set; }

    public RideStreams? Streams { get; set; }

    /// <summary>Lap boundaries and numbers; empty when the file has no laps.</summary>
    public List<RideLap> Laps { get; set; } = [];

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
