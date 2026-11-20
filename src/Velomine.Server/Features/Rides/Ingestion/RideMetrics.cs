using Velomine.Server.Features.Rides;

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
    int? AvgCadence,
    double? IntensityFactor = null,
    double? Tss = null,
    double? Trimp = null,
    double? HrTss = null,
    int[]? PowerBests = null,
    double? EfficiencyFactor = null,
    double? DecouplingPct = null,
    bool? Steady = null,
    short?[]? EstimatedPower = null,
    int? EstimatedAvgPowerW = null,
    int? EstimatedNormalizedPowerW = null,
    double? EstimatedTss = null);

/// <summary>
/// The numbers shown for a ride, worked out from its samples. Pure functions, no I/O.
/// Moving time, averages and normalized power skip pauses: gaps between samples longer than the pause threshold.
/// </summary>
public static class RideMetrics
{
    private const double StoppedSpeedMs = 0.5;
    private const int SpeedMedianWindow = 5;
    /// <summary>The most a bicycle can change speed in one second: about 36 km/h from hard braking alone.</summary>
    private const double MaxAccelerationMs2 = 10;
    private const int ElevationSmoothingWindow = 5;
    private const double ElevationThresholdM = 2;
    private const int NormalizedPowerWindowS = 30;

    public static RideMetricValues Compute(
        IReadOnlyList<Sample> samples,
        int? deviceNormalizedPowerW = null,
        double? deviceElapsedS = null,
        double? deviceMovingS = null,
        IReadOnlyList<PauseInterval>? pauses = null,
        int? ftpW = null,
        int? maxHeartRate = null,
        int? thresholdHeartRate = null,
        PowerEstimate? estimate = null)
    {
        if (samples.Count < 2) throw new RideParseException("too_short", "The ride has fewer than two samples.");

        var paused = pauses ?? [];
        var elapsed = deviceElapsedS is { } recordedElapsed && recordedElapsed >= 0
            ? recordedElapsed
            : samples[^1].T - samples[0].T;
        var pause = PauseThresholdS(samples);
        var speeds = SpeedSeries(samples, out var source, paused);

        var moving = deviceMovingS is { } recordedMoving && recordedMoving >= 0
            ? Math.Min(recordedMoving, elapsed)
            : paused.Count > 0
                ? MovingFromPauses(elapsed, paused)
                : MovingFromSamples(samples, speeds, pause);

        var distance = TotalDistance(samples, paused);
        var (gain, loss) = ElevationChange(samples.Select(s => s.Altitude).ToArray());
        var power = Resample(samples, s => s.Power, pause, paused);
        var heartRate = Resample(samples, s => s.HeartRate, pause, paused);
        var cadence = Resample(samples, s => s.Cadence, pause, paused).Where(c => c > 0).ToArray();
        var normalizedPower = deviceNormalizedPowerW ?? NormalizedPower(power);
        var (intensityFactor, tss) = TrainingLoad.PowerLoad(normalizedPower, moving, ftpW);
        var heartRateZones = maxHeartRate is { } zoneMaxHr
            ? TrainingLoad.ZoneSeconds(samples, s => s.HeartRate, zoneMaxHr, TrainingLoad.HeartRateFloor, TrainingLoad.HeartRateBounds)
            : null;
        var (efficiencyFactor, decoupling, steady) = Efficiency(PairedSeconds(samples, pause, paused));
        // Only a ride with no power at all gets estimated watts; they never feed the power numbers above.
        var estimated = estimate is null
            ? null
            : EstimatedPower.Compute(samples, speeds, pause, paused, estimate, ftpW, moving);

        return new RideMetricValues(
            elapsed,
            moving,
            distance,
            gain,
            loss,
            moving > 0 ? distance / moving : null,
            speeds.Any(s => s.HasValue) ? RobustMax([.. speeds.OfType<float>()]) : null,
            source,
            power.Length > 0 ? (int)Math.Round(power.Average()) : null,
            samples.Max(s => s.Power) is { } maxPower ? maxPower : null,
            normalizedPower,
            heartRate.Length > 0 ? (int)Math.Round(heartRate.Average()) : null,
            samples.Max(s => s.HeartRate) is { } maxHr ? maxHr : null,
            cadence.Length > 0 ? (int)Math.Round(cadence.Average()) : null,
            intensityFactor,
            tss,
            TrainingLoad.Trimp(heartRateZones),
            TrainingLoad.HrTss(samples, thresholdHeartRate, paused),
            PowerBests.ComputeFromSamples(samples, pause, paused),
            efficiencyFactor,
            decoupling,
            steady,
            estimated?.PerSample,
            estimated?.AvgPowerW,
            estimated?.NormalizedPowerW,
            estimated?.Tss);
    }

    /// <summary>
    /// One value per second of riding, from the samples that have both signals: pauses are left out, and a second
    /// whose power or heart rate the file lacks is dropped as a whole, so the two never drift apart.
    /// </summary>
    public static (double Power, double HeartRate)[] PairedSeconds(
        IReadOnlyList<Sample> samples,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses = null)
    {
        var result = new List<(double Power, double HeartRate)>();
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pauseThresholdS ||
                CrossesPause(pauses, samples[i].T, samples[i + 1].T) ||
                samples[i].Power is not { } watts || samples[i].HeartRate is not { } bpm) continue;
            for (var s = 0; s < Math.Max(1, (int)Math.Round(dt)); s++) result.Add((watts, bpm));
        }

        return [.. result];
    }

    /// <summary>The shortest ride, after the warm-up, that says anything about aerobic decoupling.</summary>
    private const int DecouplingWarmupS = 15 * 60;
    private const int DecouplingMinimumS = 40 * 60;
    private const double DecouplingSteadyVi = 1.10;

    /// <summary>
    /// Aerobic decoupling and efficiency factor (Friel): the moving seconds with a heart rate and a pedalling power,
    /// after a warm-up, split in two halves. Only a steady ride says how much heart rate drifted; every qualifying
    /// ride has its efficiency factor and whether it was steady.
    /// </summary>
    public static (double? EfficiencyFactor, double? DecouplingPct, bool? Steady) Efficiency(
        IReadOnlyList<(double Power, double HeartRate)> seconds)
    {
        // Coasting (descents, traffic) and spikes are left out, so a hilly ride does not show drift from freewheeling.
        var kept = seconds.Where(s => s.HeartRate is >= 60 and <= 220 && s.Power is >= 50 and <= 2500).ToList();
        if (kept.Count < DecouplingWarmupS + DecouplingMinimumS) return (null, null, null);
        kept.RemoveRange(0, DecouplingWarmupS);

        // Both the efficiency factor and the steadiness test use the kept seconds' own numbers, never the whole ride's:
        // a warm-up or a long descent must not make a ride look steady, nor change what it says about heart rate drift.
        var normalizedPower = (int?)NormalizedPower(kept.ConvertAll(s => s.Power)) ?? 0;
        var efficiencyFactor = Math.Round(normalizedPower / kept.Average(s => s.HeartRate), 2);
        if (normalizedPower / kept.Average(s => s.Power) > DecouplingSteadyVi) return (efficiencyFactor, null, false);

        var half = kept.Count / 2;
        var first = HalfEfficiency(kept, 0, half);
        var second = HalfEfficiency(kept, half, kept.Count);
        return (efficiencyFactor, Math.Round((first - second) / first * 100, 1), true);
    }

    /// <summary>One half's efficiency factor: the normalized power of its seconds over their mean heart rate.</summary>
    private static double HalfEfficiency(List<(double Power, double HeartRate)> kept, int from, int to)
    {
        var half = kept.GetRange(from, to - from);
        return (int?)NormalizedPower(half.ConvertAll(s => s.Power)) is { } np ? np / half.Average(s => s.HeartRate) : 0;
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

    private static double MovingFromSamples(IReadOnlyList<Sample> samples, float?[] speeds, double pause)
    {
        var moving = 0.0;
        for (var i = 1; i < samples.Count; i++)
        {
            var dt = samples[i].T - samples[i - 1].T;
            if (dt > 0 && dt <= pause && IsMoving(speeds[i - 1], speeds[i])) moving += dt;
        }
        return moving;
    }

    private static double MovingFromPauses(double elapsed, IReadOnlyList<PauseInterval> pauses)
    {
        var paused = 0.0;
        var lastEnd = 0.0;
        foreach (var interval in pauses.OrderBy(p => p.StartS))
        {
            var start = Math.Max(0, Math.Min(elapsed, interval.StartS));
            var end = Math.Max(0, Math.Min(elapsed, interval.EndS));
            var from = Math.Max(start, lastEnd);
            if (end > from) paused += end - from;
            if (end > lastEnd) lastEnd = end;
        }
        return Math.Max(0, elapsed - paused);
    }

    private static bool CrossesPause(IReadOnlyList<PauseInterval>? pauses, double from, double to) =>
        pauses is not null && pauses.Any(p => p.StartS < to && p.EndS > from);

    /// <summary>
    /// Speed per sample: the file's own speed where it has one for most samples, otherwise worked out from positions
    /// (and the cumulative distance when there are no positions). A pair that spans a timer pause is left unknown, and
    /// so is a speed that would need more than <see cref="MaxAccelerationMs2"/> to reach, which is how a burst of
    /// poor positions after a tunnel disappears. The first sample has no place of its own, so it repeats the second.
    /// </summary>
    public static float?[] SpeedSeries(
        IReadOnlyList<Sample> samples,
        out SpeedSource source,
        IReadOnlyList<PauseInterval>? pauses = null)
    {
        if (samples.Count(s => s.Speed.HasValue) * 2 >= samples.Count)
        {
            source = SpeedSource.Device;
            var device = samples.Select(s => s.Speed).ToArray();
            for (var i = 1; i < samples.Count; i++)
                if (CrossesPause(pauses, samples[i - 1].T, samples[i].T)) device[i] = null;
            return ImplausibleRemoved(device);
        }

        source = SpeedSource.Gps;
        var speeds = new float?[samples.Count];
        for (var i = 1; i < samples.Count; i++)
        {
            if (CrossesPause(pauses, samples[i - 1].T, samples[i].T)) continue;
            var dt = samples[i].T - samples[i - 1].T;
            var meters = DistanceBetween(samples[i - 1], samples[i]);
            if (dt > 0 && meters.HasValue) speeds[i] = (float)(meters.Value / dt);
        }

        speeds = ImplausibleRemoved(speeds);
        if (samples.Count > 1) speeds[0] = speeds[1];
        return speeds;
    }

    private static float?[] ImplausibleRemoved(float?[] speeds)
    {
        var last = speeds[0];
        for (var i = 1; i < speeds.Length; i++)
        {
            if (speeds[i] is not { } speed) continue;
            if (last is not { } previous || Math.Abs(speed - previous) <= MaxAccelerationMs2) last = speed;
            else speeds[i] = null;
        }

        return speeds;
    }

    /// <summary>Total distance: the device's cumulative distance if the file has it, else the sum of position steps.</summary>
    public static double TotalDistance(
        IReadOnlyList<Sample> samples,
        IReadOnlyList<PauseInterval>? pauses = null)
    {
        var cumulative = samples.Where(s => s.Distance.HasValue).Select(s => (double)s.Distance!.Value).ToArray();

        // A device cumulative distance cannot say which metres were ridden during a paused interval, so positions win
        // when the file also has timer events and positions. An indoor file has no positions, so there the cumulative
        // distance is the only source even with pauses.
        if (pauses is null || pauses.Count == 0)
        {
            if (cumulative.Length >= 2) return Math.Max(0, cumulative[^1] - cumulative[0]);
        }
        else
        {
            var total = 0.0;
            var hasPositions = false;
            for (var i = 1; i < samples.Count; i++)
            {
                if (CrossesPause(pauses, samples[i - 1].T, samples[i].T)) continue;
                if (DistanceBetween(samples[i - 1], samples[i]) is not { } meters) continue;
                hasPositions = true;
                total += meters;
            }

            if (hasPositions) return total;
            if (cumulative.Length >= 2) return Math.Max(0, cumulative[^1] - cumulative[0]);
            return 0;
        }

        var distance = 0.0;
        for (var i = 1; i < samples.Count; i++)
            distance += DistanceBetween(samples[i - 1], samples[i]) ?? 0;
        return distance;
    }

    private static double? DistanceBetween(Sample a, Sample b) =>
        a.Latitude is { } la && a.Longitude is { } lo && b.Latitude is { } lb && b.Longitude is { } lp
            ? Haversine(la, lo, lb, lp)
            : null;

    /// <summary>The distance between two points. Kept here for the rides code; see <see cref="Geo"/>.</summary>
    public static double Haversine(double lat1, double lon1, double lat2, double lon2) =>
        Geo.Metres(lat1, lon1, lat2, lon2);

    /// <summary>The largest of the sliding-window medians, so a short run of GPS glitches never becomes the maximum speed.</summary>
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

        var smooth = SmoothAltitude(values);
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
    /// A median filter removes spikes and a moving average smooths the rest, over the five values around each one.
    /// Same length as the input, so the result stays aligned with the samples it came from.
    /// </summary>
    public static double[] SmoothAltitude(IReadOnlyList<double> values)
    {
        var source = values as double[] ?? [.. values];
        var half = ElevationSmoothingWindow / 2;
        var despiked = new double[source.Length];
        for (var i = 0; i < source.Length; i++)
            despiked[i] = Median(source[Math.Max(0, i - half)..Math.Min(source.Length, i + half + 1)].ToList());

        var smooth = new double[source.Length];
        for (var i = 0; i < source.Length; i++)
            smooth[i] = despiked[Math.Max(0, i - half)..Math.Min(source.Length, i + half + 1)].Average();
        return smooth;
    }

    /// <summary>The same smoothing over a signal with gaps: each sample's altitude, null where it has none.</summary>
    public static double?[] SmoothedAltitudes(IReadOnlyList<float?> altitudes)
    {
        var positions = new List<int>(altitudes.Count);
        var values = new List<double>(altitudes.Count);
        for (var i = 0; i < altitudes.Count; i++)
            if (altitudes[i] is { } altitude)
            {
                positions.Add(i);
                values.Add(altitude);
            }

        var result = new double?[altitudes.Count];
        if (values.Count < 2) return result;
        var smooth = SmoothAltitude(values);
        for (var i = 0; i < positions.Count; i++) result[positions[i]] = smooth[i];
        return result;
    }

    /// <summary>
    /// A value for every second of riding: each sample's value is held until the next sample, and pauses are left out.
    /// </summary>
    public static double[] Resample(
        IReadOnlyList<Sample> samples,
        Func<Sample, short?> pick,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses = null)
    {
        var result = new List<double>();
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pauseThresholdS ||
                CrossesPause(pauses, samples[i].T, samples[i + 1].T) ||
                pick(samples[i]) is not { } value) continue;
            var seconds = (int)Math.Round(dt);
            for (var s = 0; s < Math.Max(1, seconds); s++) result.Add(value);
        }

        return [.. result];
    }

    /// <summary>
    /// The same seconds, each saying which sample it came from and which stretch of samples it belongs to, so a value
    /// per second can go back onto the stored samples, which are the ride streams.
    /// </summary>
    public static (int Stretch, int First, int Last, double Value)[] Seconds(
        IReadOnlyList<Sample> samples,
        Func<Sample, short?> pick,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses = null)
    {
        var result = new List<(int, int, int, double)>();
        var stretch = 0;
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pauseThresholdS ||
                CrossesPause(pauses, samples[i].T, samples[i + 1].T) ||
                pick(samples[i]) is not { } value)
            {
                stretch++;
                continue;
            }

            // Every second of the stretch belongs to the sample it starts from, so a gapped recording never puts a
            // second past the end of the arrays or two samples late.
            var seconds = Math.Max(1, (int)Math.Round(dt));
            for (var s = 0; s < seconds; s++) result.Add((stretch, i, i, value));
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

    internal static double Median(List<double> values)
    {
        values.Sort();
        var middle = values.Count / 2;
        return values.Count % 2 == 1 ? values[middle] : (values[middle - 1] + values[middle]) / 2;
    }
}
