using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// One lap's numbers. The boundaries come from the file; the numbers are recomputed from the samples in the range,
/// with the same moving-time and normalized-power rules as the ride, so the laps add up to what the ride shows.
/// </summary>
public sealed class RideLap
{
    public Guid RideId { get; set; }

    /// <summary>1-based, in the order the file recorded them.</summary>
    public int Index { get; set; }

    public double StartS { get; set; }

    public double EndS { get; set; }

    public double DurationS { get; set; }

    public double MovingS { get; set; }

    public double DistanceM { get; set; }

    public double? AvgSpeedMs { get; set; }

    public double? MaxSpeedMs { get; set; }

    public int? AvgPowerW { get; set; }

    public int? MaxPowerW { get; set; }

    public int? AvgHeartRate { get; set; }

    public int? MaxHeartRate { get; set; }

    public int? AvgCadence { get; set; }

    public double? ElevationGainM { get; set; }
}

/// <summary>Turns the file's lap boundaries into stored laps, computing each one from the ride's samples.</summary>
public static class LapMetrics
{
    public static List<RideLap> Build(
        Guid rideId,
        IReadOnlyList<ParsedLap> laps,
        IReadOnlyList<Sample> samples,
        IReadOnlyList<PauseInterval> pauses,
        int? ftpW,
        int? maxHeartRate)
    {
        if (laps.Count == 0 || samples.Count < 2) return [];

        var end = samples[^1].T;
        var ranges = laps
            .OrderBy(l => l.StartS)
            .Select(l => new ParsedLap(Math.Max(0, l.StartS), Math.Min(end, l.EndS)))
            .Where(l => l.EndS > l.StartS)
            .ToList();
        if (ranges.Count == 0) return [];

        // The first lap starts with the ride and the last ends with it, so a gap at either end cannot lose time.
        ranges[0] = ranges[0] with { StartS = 0 };
        ranges[^1] = ranges[^1] with { EndS = end };

        var result = new List<RideLap>(ranges.Count);
        foreach (var range in ranges)
        {
            var lapSamples = samples
                .Where(s => s.T >= range.StartS && s.T <= range.EndS)
                .Select(s => s with { T = s.T - range.StartS })
                .ToList();
            if (lapSamples.Count < 2) continue;

            var lapPauses = pauses
                .Select(p => new PauseInterval(
                    Math.Max(0, p.StartS - range.StartS),
                    Math.Min(range.EndS, p.EndS) - range.StartS))
                .Where(p => p.EndS > p.StartS)
                .ToList();

            RideMetricValues metrics;
            try
            {
                metrics = RideMetrics.Compute(
                    lapSamples,
                    pauses: lapPauses,
                    ftpW: ftpW,
                    maxHeartRate: maxHeartRate);
            }
            catch (RideParseException)
            {
                continue;
            }

            result.Add(new RideLap
            {
                RideId = rideId,
                Index = result.Count + 1,
                StartS = range.StartS,
                EndS = range.EndS,
                DurationS = metrics.ElapsedS,
                MovingS = metrics.MovingS,
                DistanceM = metrics.DistanceM,
                AvgSpeedMs = metrics.AvgSpeedMs,
                MaxSpeedMs = metrics.MaxSpeedMs,
                AvgPowerW = metrics.AvgPowerW,
                MaxPowerW = metrics.MaxPowerW,
                AvgHeartRate = metrics.AvgHeartRate,
                MaxHeartRate = metrics.MaxHeartRate,
                AvgCadence = metrics.AvgCadence,
                ElevationGainM = metrics.ElevationGainM,
            });
        }

        return result;
    }
}
