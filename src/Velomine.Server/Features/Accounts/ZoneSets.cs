using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Accounts;

/// <summary>The three sets of zone bounds, as the API names them in the route and the response.</summary>
public static class ZoneSets
{
    public const string Power = "power";
    public const string HeartRateMax = "heart-rate-max";
    public const string HeartRateThreshold = "heart-rate-threshold";

    /// <summary>Custom bounds are fractions of the reference, and are valid inside these.</summary>
    public const double MinBound = 0.30;

    public const double MaxBound = 2.00;

    /// <summary>The bounds a set needs: one per zone but the open-ended top one.</summary>
    public static int BoundCount(string set) => set == Power ? 6 : 4;

    public static bool IsKnown(string set) => set is Power or HeartRateMax or HeartRateThreshold;

    /// <summary>
    /// The zones in use: for each set its bounds (the rider's own when they set some), whether they are custom, the
    /// absolute watts or bpm they give today, and the heart-rate model those zones are read against.
    /// </summary>
    public static ZonesResponse Of(User user, TimeProvider time)
    {
        var (max, threshold) = HeartRates.For(user, time);
        return new ZonesResponse(
            [
                Set(Power, user.FtpW, source: null, user.PowerZoneBounds, TrainingLoad.PowerBounds),
                Set(HeartRateMax, max?.Bpm, max?.Source, user.HeartRateMaxZoneBounds, TrainingLoad.HeartRateBounds),
                Set(
                    HeartRateThreshold,
                    threshold?.Bpm,
                    threshold?.Source,
                    user.HeartRateThresholdZoneBounds,
                    TrainingLoad.ThresholdHeartRateBounds),
            ],
            TrainingLoad.HeartRateZoneFor(max, threshold, user.HeartRateMaxZoneBounds, user.HeartRateThresholdZoneBounds)?.Model);
    }

    private static ZoneSetResponse Set(string set, int? reference, string? source, double[]? custom, double[] standard)
    {
        var bounds = custom ?? standard;
        // Without a reference there is nothing to place the zones on, so the ranges are empty rather than zero.
        var zones = reference is { } bpm
            ? TrainingLoad.Zones(new double[bounds.Length + 1], bpm, 0, bounds)
            : [];
        return new ZoneSetResponse(set, bounds, Custom: custom is not null, reference, source, zones);
    }
}
