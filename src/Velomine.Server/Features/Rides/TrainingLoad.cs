namespace Velomine.Server.Features.Rides;

using Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Training zones and load. Zones are fractions of a reference (maximum heart rate or FTP), the way cycling
/// training books describe them. Power load is TSS; heart-rate load is a zone-weighted TRIMP in points.
/// </summary>
public static class TrainingLoad
{
    /// <summary>Zone 1 starts here; time below it is not training time.</summary>
    public const double HeartRateFloor = 0.50;

    /// <summary>Upper bounds of heart-rate zones Z1–Z4; Z5 is open-ended. Ignored below <see cref="HeartRateFloor"/>.</summary>
    public static readonly double[] HeartRateBounds = [0.60, 0.70, 0.80, 0.90];

    /// <summary>Upper bounds of power zones Z1–Z6; Z7 is open-ended. Coasting (0 W) is not training time.</summary>
    public static readonly double[] PowerBounds = [0.55, 0.75, 0.90, 1.05, 1.20, 1.50];

    private const double MaxSampleGapS = 30;

    /// <summary>Seconds in each zone, from samples that carry a time.</summary>
    public static double[] ZoneSeconds(
        IReadOnlyList<Sample> samples,
        Func<Sample, short?> pick,
        double reference,
        double floor,
        double[] upperBounds)
    {
        var seconds = new double[upperBounds.Length + 1];
        if (reference <= 0) return seconds;
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > MaxSampleGapS) continue;
            Add(seconds, pick(samples[i]), reference, floor, upperBounds, dt);
        }
        return seconds;
    }

    /// <summary>Seconds in each zone, from the streams stored for a ride.</summary>
    public static double[] ZoneSeconds(
        IReadOnlyList<short?> values,
        IReadOnlyList<double> time,
        double reference,
        double floor,
        double[] upperBounds)
    {
        var seconds = new double[upperBounds.Length + 1];
        if (reference <= 0) return seconds;
        var count = Math.Min(values.Count, time.Count);
        for (var i = 0; i + 1 < count; i++)
        {
            var dt = time[i + 1] - time[i];
            if (dt <= 0 || dt > MaxSampleGapS) continue;
            Add(seconds, values[i], reference, floor, upperBounds, dt);
        }
        return seconds;
    }

    private static void Add(double[] seconds, short? raw, double reference, double floor, double[] upperBounds, double dt)
    {
        if (raw is not { } value || value <= 0) return;
        var ratio = value / reference;
        if (ratio < floor) return;
        var zone = 0;
        while (zone < upperBounds.Length && ratio >= upperBounds[zone]) zone++;
        seconds[zone] += dt;
    }

    /// <summary>The zones with their absolute range, for display. An open-ended top zone has no <c>To</c>.</summary>
    public static ZoneTime[] Zones(
        IReadOnlyList<short?> values,
        IReadOnlyList<double> time,
        double reference,
        double floor,
        double[] upperBounds) =>
        Zones(ZoneSeconds(values, time, reference, floor, upperBounds), reference, floor, upperBounds);

    /// <summary>The zones from already counted seconds.</summary>
    public static ZoneTime[] Zones(double[] seconds, double reference, double floor, double[] upperBounds)
    {
        var zones = new ZoneTime[seconds.Length];
        for (var i = 0; i < seconds.Length; i++)
        {
            var lower = i == 0 ? floor : upperBounds[i - 1];
            var from = (int)Math.Round(reference * lower);
            int? to = i < upperBounds.Length ? (int)Math.Round(reference * upperBounds[i]) - 1 : null;
            zones[i] = new ZoneTime(i + 1, from, to, Math.Round(seconds[i]));
        }
        return zones;
    }

    /// <summary>Intensity factor and TSS from normalized power, moving time and FTP.</summary>
    public static (double? IntensityFactor, double? Tss) PowerLoad(int? normalizedPowerW, double movingS, int? ftpW)
    {
        if (normalizedPowerW is not { } np || ftpW is not { } ftp || np <= 0 || ftp <= 0 || movingS <= 0)
            return (null, null);

        var intensity = (double)np / ftp;
        var tss = movingS * np * intensity / (ftp * 3600) * 100;
        return (Math.Round(intensity, 2), Math.Round(tss, 1));
    }

    /// <summary>Zone-weighted minutes: one point per minute in Z1, five in Z5.</summary>
    public static double? Trimp(double[]? heartRateZoneSeconds)
    {
        if (heartRateZoneSeconds is null) return null;
        double weighted = 0, total = 0;
        for (var i = 0; i < heartRateZoneSeconds.Length; i++)
        {
            weighted += heartRateZoneSeconds[i] * (i + 1);
            total += heartRateZoneSeconds[i];
        }
        return total > 0 ? Math.Round(weighted / 60.0, 1) : null;
    }
}
