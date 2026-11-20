namespace Velomine.Server.Features.Rides;

/// <summary>Time in one training zone. <c>To</c> is null for the open-ended top zone. Boundaries are bpm or watts.</summary>
public sealed record ZoneTime(int Zone, int From, int? To, double Seconds);

/// <summary>
/// A ride as the API shows it. Times are UTC; distances in metres, times in seconds, speeds in metres per second.
/// Title and Description are the member's own words (null when empty); Version is the ride's concurrency token, which
/// an edit of them sends back.
/// </summary>
public sealed record RideResponse(
    Guid Id,
    string Status,
    string? Error,
    Guid? DuplicateOf,
    string FileName,
    DateTimeOffset UploadedAt,
    DateTimeOffset? StartTime,
    int? UtcOffsetMinutes,
    string? Device,
    string? Discipline,
    string? Assist,
    string? Environment,
    bool? Commute,
    double? DistanceM,
    double? ElapsedS,
    double? MovingS,
    double? ElevationGainM,
    double? ElevationLossM,
    double? AvgSpeedMs,
    double? MaxSpeedMs,
    string? SpeedSource,
    int? AvgPowerW,
    int? MaxPowerW,
    int? NormalizedPowerW,
    double? IntensityFactor,
    double? Tss,
    double? Trimp,
    int? AvgHeartRate,
    int? MaxHeartRate,
    int? AvgCadence,
    Guid? BikeId,
    string? Title,
    string? Description,
    long Version,
    ZoneTime[]? HeartRateZones = null,
    ZoneTime[]? PowerZones = null,
    Analytics.PowerRecord[]? PowerRecords = null,
    // A suggestion is the owner's own question to answer: copied by hand, never by From, so no hand-built response
    // can carry one. GetRide sets it; WithoutTrainingLoad and PrivacyRules.ForViewer clear it.
    int? FtpSuggestionW = null,
    string? FtpSuggestionMethod = null,
    Guid? FtpSuggestionId = null,
    // What this ride did to a heart-rate number when it was first read: one of Analytics.HeartRateNotes, owner only.
    // Copied by hand like an FTP suggestion, so WithoutTrainingLoad clears it and no other response carries it.
    string? HeartRateNote = null,
    // Derived from power: RideDetails sets them, WithoutTrainingLoad and PrivacyRules.ForViewer clear them.
    int? MinWPrimeBalanceJ = null,
    int? WPrimeJ = null,
    // From power and heart rate together: WithoutTrainingLoad clears them, and PrivacyRules.ForViewer does too when
    // it hides either signal.
    double? EfficiencyFactor = null,
    double? DecouplingPct = null,
    bool? Steady = null,
    // The three heart-rate notes, owner only: the legacy one (the maximum's first, then the threshold's), the
    // maximum's and the threshold's own. Set by RideResponse.From, cleared like an FTP suggestion.
    string? HeartRateMaxNote = null,
    string? HeartRateThresholdNote = null,
    // Which model the heart-rate zones came from and the reference they are fractions of: a coach or a share viewer
    // sees them too (they are the rider's zones), hidden by the heart-rate privacy switch.
    string? HeartRateZoneModel = null,
    int? HeartRateZoneReferenceBpm = null,
    string? HeartRateZoneReferenceSource = null)
{
    public static RideResponse From(Ride r) => new(
        r.Id,
        r.Status.ToString().ToLowerInvariant(),
        r.Error,
        r.DuplicateOf,
        r.FileName,
        r.UploadedAt,
        r.StartTime,
        r.UtcOffsetMinutes,
        r.Device,
        r.Discipline,
        r.Assist,
        r.Environment,
        r.Commute,
        r.DistanceM,
        r.ElapsedS,
        r.MovingS,
        r.ElevationGainM,
        r.ElevationLossM,
        r.AvgSpeedMs,
        r.MaxSpeedMs,
        r.SpeedSource?.ToString().ToLowerInvariant(),
        r.AvgPowerW,
        r.MaxPowerW,
        r.NormalizedPowerW,
        r.IntensityFactor,
        r.Tss,
        r.Trimp,
        r.AvgHeartRate,
        r.MaxHeartRate,
        r.AvgCadence,
        r.BikeId,
        r.Title,
        r.Description,
        r.Version,
        HeartRateNote: r.HeartRateNote,
        EfficiencyFactor: r.EfficiencyFactor,
        DecouplingPct: r.DecouplingPct,
        Steady: r.Steady,
        HeartRateMaxNote: Analytics.HeartRateNotes.IsMax(r.HeartRateNote) ? r.HeartRateNote : null,
        HeartRateThresholdNote: r.HeartRateThresholdNote);

    /// <summary>The same ride without training load, for a viewer allowed to see rides but not analytics.</summary>
    public RideResponse WithoutTrainingLoad() => this with
    {
        IntensityFactor = null,
        Tss = null,
        Trimp = null,
        HeartRateZones = null,
        PowerZones = null,
        PowerRecords = null,
        FtpSuggestionW = null,
        FtpSuggestionMethod = null,
        FtpSuggestionId = null,
        HeartRateNote = null,
        HeartRateMaxNote = null,
        HeartRateThresholdNote = null,
        HeartRateZoneModel = null,
        HeartRateZoneReferenceBpm = null,
        HeartRateZoneReferenceSource = null,
        MinWPrimeBalanceJ = null,
        WPrimeJ = null,
        EfficiencyFactor = null,
        DecouplingPct = null,
        Steady = null,
    };
}
