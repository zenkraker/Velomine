namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Decides whether two recorded files are the same ride. Two apps never write the same bytes, so this looks at what
/// the ride was: the same elapsed time, and the same distance unless the file has no distance (an indoor ride).
/// </summary>
public static class RideMatch
{
    /// <summary>Elapsed times further apart than this are different rides.</summary>
    public const double ElapsedToleranceS = 60;

    /// <summary>Distances may differ by this much, or by two percent, whichever is larger.</summary>
    public const double DistanceToleranceM = 200;

    public static bool SameRide(double elapsedS, double? distanceM, double? otherElapsedS, double? otherDistanceM)
    {
        if (otherElapsedS is not { } other || Math.Abs(elapsedS - other) > ElapsedToleranceS) return false;
        if (distanceM is not { } distance || otherDistanceM is not { } otherDistance) return true;
        return Math.Abs(distance - otherDistance) <= Math.Max(DistanceToleranceM, Math.Max(distance, otherDistance) * 0.02);
    }
}
