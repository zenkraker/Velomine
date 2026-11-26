using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// What the watt estimate needs besides the samples: the rider's weight, the bike (its kind picks the row, its own
/// weight overrides the row's default), and what the ride says about itself when there is no bike.
/// </summary>
public sealed record PowerEstimate(
    double? RiderWeightKg,
    double? BikeWeightKg,
    string? BikeKind,
    string? Discipline,
    string? Environment = null,
    string? Assist = null)
{
    /// <summary>
    /// Whether the ride can have an estimate at all: outdoors (null counts as outdoors), not assisted, and with the
    /// rider's weight. An e-bike ride is left out because the motor's share of the work is unknown.
    /// </summary>
    public bool Applies => RiderWeightKg is not null
        && Environment is not (Environments.Indoor or Environments.Virtual)
        && Assist != Assists.EBike
        && BikeKind != "ebike";
}

/// <summary>The estimated watts of one ride: a value per sample, its average, its normalized power and its TSS.</summary>
public sealed record EstimatedPowerValues(short?[]? PerSample, int? AvgPowerW, int? NormalizedPowerW, double? Tss);

/// <summary>
/// Watts estimated from speed, slope and weight for a ride with no power meter, the way Strava describes its own:
/// the standard cycling power model (Martin et al. 1998) worked out per recorded sample, with no wind and 15 °C still
/// air, and the watts of the rider and bike rather than at the cranks, so no drivetrain loss. They are shown and give
/// an estimated TSS; they never feed power bests, the power curve, FTP estimates, records, critical power, W' balance,
/// decoupling or power zones.
/// </summary>
public static class EstimatedPower
{
    private const double Gravity = 9.81;
    /// <summary>Strava assumes 15 °C and still air, so one density with no altitude correction.</summary>
    private const double AirDensity = 1.225;
    private const double MaxWatts = 2000;
    private const double MaxGrade = 0.25;
    private const double MaxAccelerationMs2 = 1.5;
    private const double StoppedSpeedMs = 0.5;
    private const int SpeedMedianWindow = 5;
    /// <summary>The grade looks five seconds either side of the sample, over at least this many metres.</summary>
    private const int GradeWindowS = 5;
    private const double MinGradeDistanceM = 5;
    /// <summary>The stand-in FTP for a rider who has none: 2.5 W/kg, a typical recreational rider.</summary>
    private const double StandInWattsPerKg = 2.5;

    /// <summary>The rolling resistance, the drag area and the bike weight of a kind of bike; "other" for an unknown kind.</summary>
    public static (double Crr, double CdA, double WeightKg) Row(string? kind) => kind switch
    {
        "road" => (0.004, 0.32, 8.5),
        "timetrial" or "track" => (0.004, 0.25, 9),
        "gravel" => (0.008, 0.36, 9.5),
        "mountain" => (0.012, 0.45, 13),
        "city" => (0.008, 0.55, 15),
        _ => (0.006, 0.40, 11),
    };

    /// <summary>The kind of bike a discipline stands for, when the ride has no bike; null for the "other" row.</summary>
    public static string? KindFor(string? discipline) => discipline switch
    {
        Disciplines.Road => "road",
        Disciplines.Gravel => "gravel",
        Disciplines.Mountain => "mountain",
        Disciplines.Track => "track",
        _ => null,
    };

    /// <summary>
    /// One sample's power, as the watts the rider and bike use together: a coasting, braking or descending sample is
    /// 0 W, and so is a stopped one. <paramref name="accelerationMs2"/> is limited to ±1.5 m/s², the grade to ±25 %.
    /// </summary>
    public static double Watts(
        double speedMs,
        double accelerationMs2,
        double grade,
        double massKg,
        double crr,
        double cda)
    {
        if (speedMs < StoppedSpeedMs) return 0;
        var slope = Math.Atan(Math.Clamp(grade, -MaxGrade, MaxGrade));
        var force = massKg * Gravity * (crr * Math.Cos(slope) + Math.Sin(slope))
            + 0.5 * AirDensity * cda * speedMs * speedMs
            + massKg * Math.Clamp(accelerationMs2, -MaxAccelerationMs2, MaxAccelerationMs2);
        return Math.Clamp(force * speedMs, 0, MaxWatts);
    }

    /// <summary>
    /// The estimate for a ride, or null when it cannot have one: it has power already, no speed, no altitude, or no
    /// rider weight. The TSS uses the FTP at read, or the 2.5 W/kg stand-in when the rider has none; the stand-in is
    /// never stored as the rider's FTP.
    /// </summary>
    public static EstimatedPowerValues? Compute(
        IReadOnlyList<Sample> samples,
        float?[] speeds,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses,
        PowerEstimate estimate,
        int? ftpW,
        double movingS)
    {
        if (!estimate.Applies || samples.Any(s => s.Power is not null)) return null;
        if (estimate.RiderWeightKg is not { } riderWeightKg) return null;

        var (crr, cda, defaultBikeWeightKg) = Row(estimate.BikeKind ?? KindFor(estimate.Discipline));
        var mass = riderWeightKg + (estimate.BikeWeightKg ?? defaultBikeWeightKg);
        var altitudes = RideMetrics.SmoothedAltitudes([.. samples.Select(s => s.Altitude)]);
        var speedsMedian = MedianSpeeds(speeds);
        if (altitudes.All(a => a is null) || speedsMedian.All(s => s is null)) return null;

        var watts = new short?[samples.Count];
        for (var i = 0; i < samples.Count; i++)
        {
            if (IsPaused(samples, i, pauseThresholdS, pauses))
            {
                watts[i] = 0;
                continue;
            }

            if (speedsMedian[i] is not { } speed) continue;
            var acceleration = i > 0 && speedsMedian[i - 1] is { } before && samples[i].T > samples[i - 1].T
                ? (speed - before) / (samples[i].T - samples[i - 1].T)
                : 0;
            var grade = Grade(samples, altitudes, speedsMedian, i);
            watts[i] = (short)Math.Round(Watts(speed, acceleration, grade, mass, crr, cda));
        }

        if (watts.All(w => w is null)) return null;
        var seconds = Hold(samples, watts, pauseThresholdS, pauses);
        if (seconds.Length == 0) return null;

        var normalizedPowerW = RideMetrics.NormalizedPower(seconds);
        var (_, tss) = TrainingLoad.PowerLoad(normalizedPowerW, movingS, ftpW ?? (int)Math.Round(StandInWattsPerKg * riderWeightKg));
        return new EstimatedPowerValues(watts, (int)Math.Round(seconds.Average()), normalizedPowerW, tss);
    }

    /// <summary>Speed smoothed by the median of the five samples around each one, so GPS jitter does not become watts.</summary>
    private static double?[] MedianSpeeds(float?[] speeds)
    {
        var half = SpeedMedianWindow / 2;
        var result = new double?[speeds.Length];
        for (var i = 0; i < speeds.Length; i++)
        {
            var present = speeds[Math.Max(0, i - half)..Math.Min(speeds.Length, i + half + 1)]
                .Where(s => s.HasValue)
                .Select(s => (double)s!.Value)
                .ToList();
            if (present.Count > 0) result[i] = RideMetrics.Median(present);
        }

        return result;
    }

    /// <summary>
    /// The grade around one sample: the smoothed altitude change over the ten seconds centred on it, divided by the
    /// distance those seconds cover. Under five metres of distance the slope means nothing, so it is flat.
    /// </summary>
    private static double Grade(IReadOnlyList<Sample> samples, double?[] altitudes, double?[] speeds, int i)
    {
        var from = i;
        while (from > 0 && samples[from - 1].T >= samples[i].T - GradeWindowS) from--;
        var to = i;
        while (to + 1 < samples.Count && samples[to + 1].T <= samples[i].T + GradeWindowS) to++;
        if (to <= from || altitudes[from] is not { } low || altitudes[to] is not { } high) return 0;

        var distance = 0.0;
        for (var k = from; k < to; k++)
            distance += ((speeds[k] ?? 0) + (speeds[k + 1] ?? 0)) / 2 * (samples[k + 1].T - samples[k].T);
        if (distance < MinGradeDistanceM) return 0;

        return (high - low) / distance;
    }

    /// <summary>One value per second of riding, the sample's value held until the next one and pauses left out.</summary>
    private static double[] Hold(
        IReadOnlyList<Sample> samples,
        short?[] values,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses)
    {
        var result = new List<double>();
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pauseThresholdS
                || CrossesPause(pauses, samples[i].T, samples[i + 1].T)
                || values[i] is not { } value) continue;
            for (var s = 0; s < Math.Max(1, (int)Math.Round(dt)); s++) result.Add(value);
        }

        return [.. result];
    }

    private static bool IsPaused(
        IReadOnlyList<Sample> samples,
        int i,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses) =>
        (i > 0 && samples[i].T - samples[i - 1].T > pauseThresholdS)
        || (i + 1 < samples.Count && samples[i + 1].T - samples[i].T > pauseThresholdS)
        || (pauses is not null && pauses.Any(p => p.StartS <= samples[i].T && p.EndS > samples[i].T));

    private static bool CrossesPause(IReadOnlyList<PauseInterval>? pauses, double from, double to) =>
        pauses is not null && pauses.Any(p => p.StartS < to && p.EndS > from);
}
