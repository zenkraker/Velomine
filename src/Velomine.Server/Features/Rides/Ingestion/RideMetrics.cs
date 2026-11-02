namespace Velomine.Server.Features.Rides.Ingestion;

public sealed record RideMetricValues(
    double ElapsedS,
    double MovingS,
    double DistanceM,
    double? ElevationGainM,
    double? ElevationLossM,
    double? AvgSpeedMs,
    double? MaxSpeedMs,
    SpeedSource SpeedSource,
    int? AvgPowerW,
    int? MaxPowerW,
    int? NormalizedPowerW,
    int? AvgHeartRate,
    int? MaxHeartRate,
    int? AvgCadence);

/// <summary>
/// The numbers shown for a ride, worked out from its samples. Pure functions, no I/O.
/// Moving time, averages and normalized power skip pauses: gaps between samples longer than the pause threshold.
/// </summary>
public static class RideMetrics
{
    private const double StoppedSpeedMs = 0.5;
    private const int SpeedMedianWindow = 5;
    private const int ElevationSmoothingWindow = 5;
    private const double ElevationThresholdM = 2;
    private const int NormalizedPowerWindowS = 30;

    public static RideMetricValues Compute(IReadOnlyList<Sample> samples, int? deviceNormalizedPowerW = null)
    {
        if (samples.Count < 2) throw new RideParseException("too_short", "The ride has fewer than two samples.");

        var elapsed = samples[^1].T - samples[0].T;
        var pause = PauseThresholdS(samples);
        var speeds = SpeedSeries(samples, out var source);

        var moving = 0.0;
        for (var i = 1; i < samples.Count; i++)
        {
            var dt = samples[i].T - samples[i - 1].T;
            if (dt > 0 && dt <= pause && IsMoving(speeds[i - 1], speeds[i])) moving += dt;
        }

        var distance = TotalDistance(samples);
        var (gain, loss) = ElevationChange(samples.Select(s => s.Altitude).ToArray());
        var power = Resample(samples, s => s.Power, pause);
        var heartRate = Resample(samples, s => s.HeartRate, pause);
        var cadence = Resample(samples, s => s.Cadence, pause).Where(c => c > 0).ToArray();

        return new RideMetricValues(
            elapsed,
            moving,
            distance,
            gain,
            loss,
            moving > 0 ? distance / moving : null,
            speeds.Any(s => s.HasValue) ? RobustMax(speeds.Select(s => s ?? 0).ToArray()) : null,
            source,
            power.Length > 0 ? (int)Math.Round(power.Average()) : null,
            samples.Max(s => s.Power) is { } maxPower ? maxPower : null,
            deviceNormalizedPowerW ?? NormalizedPower(power),
            heartRate.Length > 0 ? (int)Math.Round(heartRate.Average()) : null,
            samples.Max(s => s.HeartRate) is { } maxHr ? maxHr : null,
            cadence.Length > 0 ? (int)Math.Round(cadence.Average()) : null);
    }

    /// <summary>A gap this long between samples is a pause (the device stopped recording), not riding.</summary>
    public static double PauseThresholdS(IReadOnlyList<Sample> samples)
    {
        var gaps = new List<double>(samples.Count);
        for (var i = 1; i < samples.Count; i++)
            if (samples[i].T > samples[i - 1].T) gaps.Add(samples[i].T - samples[i - 1].T);
        return gaps.Count == 0 ? 30 : Math.Max(30, 5 * Median(gaps));
    }

    private static bool IsMoving(float? before, float? after) => (before ?? after ?? StoppedSpeedMs + 1) > StoppedSpeedMs
        || (after ?? before ?? StoppedSpeedMs + 1) > StoppedSpeedMs;

    /// <summary>
    /// Speed per sample: the file's own speed where it has one for most samples, otherwise worked out from positions
    /// (and the cumulative distance when there are no positions).
    /// </summary>
    public static float?[] SpeedSeries(IReadOnlyList<Sample> samples, out SpeedSource source)
    {
        if (samples.Count(s => s.Speed.HasValue) * 2 >= samples.Count)
        {
            source = SpeedSource.Device;
            return samples.Select(s => s.Speed).ToArray();
        }

        source = SpeedSource.Gps;
        var speeds = new float?[samples.Count];
        for (var i = 1; i < samples.Count; i++)
        {
            var dt = samples[i].T - samples[i - 1].T;
            var meters = DistanceBetween(samples[i - 1], samples[i]);
            if (dt > 0 && meters.HasValue) speeds[i] = (float)(meters.Value / dt);
        }

        if (samples.Count > 1) speeds[0] = speeds[1];
        return speeds;
    }

    /// <summary>Total distance: the device's cumulative distance if the file has it, else the sum of position steps.</summary>
    public static double TotalDistance(IReadOnlyList<Sample> samples)
    {
        var cumulative = samples.Where(s => s.Distance.HasValue).Select(s => (double)s.Distance!.Value).ToArray();
        if (cumulative.Length >= 2) return Math.Max(0, cumulative[^1] - cumulative[0]);

        var total = 0.0;
        for (var i = 1; i < samples.Count; i++) total += DistanceBetween(samples[i - 1], samples[i]) ?? 0;
        return total;
    }

    private static double? DistanceBetween(Sample a, Sample b) =>
        a.Latitude is { } la && a.Longitude is { } lo && b.Latitude is { } lb && b.Longitude is { } lp
            ? Haversine(la, lo, lb, lp)
            : null;

    public static double Haversine(double lat1, double lon1, double lat2, double lon2)
    {
        const double EarthRadiusM = 6_371_000;
        static double Rad(double deg) => deg * Math.PI / 180;
        var dLat = Rad(lat2 - lat1);
        var dLon = Rad(lon2 - lon1);
        var h = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
            + Math.Cos(Rad(lat1)) * Math.Cos(Rad(lat2)) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return 2 * EarthRadiusM * Math.Asin(Math.Sqrt(h));
    }

    /// <summary>The largest of the sliding-window medians, so one GPS glitch never becomes the maximum speed.</summary>
    public static double RobustMax(IReadOnlyList<float> values)
    {
        if (values.Count == 0) return 0;
        if (values.Count < SpeedMedianWindow) return values.Max();
        var best = 0.0;
        for (var i = 0; i + SpeedMedianWindow <= values.Count; i++)
            best = Math.Max(best, Median(values.Skip(i).Take(SpeedMedianWindow).Select(v => (double)v).ToList()));
        return best;
    }

    /// <summary>
    /// Total climbing and descending. A median filter removes spikes and a moving average smooths the rest; then a
    /// change only counts once the altitude has moved ElevationThresholdM from the last counted point, so GPS and
    /// barometer noise adds nothing.
    /// </summary>
    public static (double? Gain, double? Loss) ElevationChange(IReadOnlyList<float?> altitudes)
    {
        var values = altitudes.Where(a => a.HasValue).Select(a => (double)a!.Value).ToArray();
        if (values.Length < 2) return (null, null);

        var half = ElevationSmoothingWindow / 2;
        var despiked = new double[values.Length];
        for (var i = 0; i < values.Length; i++)
            despiked[i] = Median(values[Math.Max(0, i - half)..Math.Min(values.Length, i + half + 1)].ToList());

        var smooth = new double[values.Length];
        for (var i = 0; i < values.Length; i++)
            smooth[i] = despiked[Math.Max(0, i - half)..Math.Min(values.Length, i + half + 1)].Average();

        double gain = 0, loss = 0, reference = smooth[0];
        foreach (var altitude in smooth)
        {
            var change = altitude - reference;
            if (Math.Abs(change) < ElevationThresholdM) continue;
            if (change > 0) gain += change;
            else loss -= change;
            reference = altitude;
        }

        return (gain, loss);
    }

    /// <summary>
    /// A value for every second of riding: each sample's value is held until the next sample, and pauses are left out.
    /// </summary>
    public static double[] Resample(IReadOnlyList<Sample> samples, Func<Sample, short?> pick, double pauseThresholdS)
    {
        var result = new List<double>();
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pauseThresholdS || pick(samples[i]) is not { } value) continue;
            var seconds = (int)Math.Round(dt);
            for (var s = 0; s < Math.Max(1, seconds); s++) result.Add(value);
        }

        return [.. result];
    }

    /// <summary>
    /// Normalized power: a 30-second rolling average of the 1 Hz power, raised to the fourth power, averaged,
    /// then the fourth root. Null for less than 30 seconds of power.
    /// </summary>
    public static int? NormalizedPower(IReadOnlyList<double> power1Hz)
    {
        if (power1Hz.Count < NormalizedPowerWindowS) return null;

        double windowSum = 0, fourthPowers = 0;
        var windows = 0;
        for (var i = 0; i < power1Hz.Count; i++)
        {
            windowSum += power1Hz[i];
            if (i >= NormalizedPowerWindowS) windowSum -= power1Hz[i - NormalizedPowerWindowS];
            if (i < NormalizedPowerWindowS - 1) continue;
            fourthPowers += Math.Pow(windowSum / NormalizedPowerWindowS, 4);
            windows++;
        }

        return (int)Math.Round(Math.Pow(fourthPowers / windows, 0.25));
    }

    private static double Median(List<double> values)
    {
        values.Sort();
        var middle = values.Count / 2;
        return values.Count % 2 == 1 ? values[middle] : (values[middle - 1] + values[middle]) / 2;
    }
}
