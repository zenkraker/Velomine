namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Best mean maximal power for the durations a power curve shows. Windows stay inside one uninterrupted stretch:
/// a pause or a gap between samples ends the stretch, so a long stop never creates a false effort across it.
/// </summary>
public static class PowerBests
{
    /// <summary>1 s, 5 s, 15 s, 30 s, 1 m, 2 m, 5 m, 10 m, 20 m, 30 m and 60 m.</summary>
    public static readonly int[] Durations = [1, 5, 15, 30, 60, 120, 300, 600, 1200, 1800, 3600];

    /// <summary>One value per <see cref="Durations"/> entry; zero when a stretch is shorter than that duration.</summary>
    public static int[] Compute(IReadOnlyList<double> power1Hz) => Compute([power1Hz]);

    /// <summary>The same, for rides split into uninterrupted stretches.</summary>
    public static int[] Compute(IReadOnlyList<IReadOnlyList<double>> stretches)
    {
        var best = new int[Durations.Length];
        for (var d = 0; d < Durations.Length; d++)
        {
            var seconds = Durations[d];
            double peak = 0;
            foreach (var stretch in stretches)
            {
                if (stretch.Count < seconds) continue;

                double window = 0;
                for (var i = 0; i < stretch.Count; i++)
                {
                    window += stretch[i];
                    if (i >= seconds) window -= stretch[i - seconds];
                    if (i < seconds - 1) continue;
                    var mean = window / seconds;
                    if (mean > peak) peak = mean;
                }
            }

            best[d] = (int)Math.Round(peak);
        }

        return best;
    }

    /// <summary>Best efforts from the parsed samples, using the same pause rules as moving time and normalized power.</summary>
    public static int[] ComputeFromSamples(
        IReadOnlyList<Sample> samples,
        double pauseThresholdS,
        IReadOnlyList<PauseInterval>? pauses)
    {
        var stretches = new List<IReadOnlyList<double>>();
        List<double>? current = null;

        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0) continue;
            if (dt > pauseThresholdS ||
                CrossesPause(pauses, samples[i].T, samples[i + 1].T) ||
                samples[i].Power is not { } value)
            {
                if (current is { Count: > 0 }) stretches.Add(current);
                current = null;
                continue;
            }

            current ??= [];
            var seconds = Math.Max(1, (int)Math.Round(dt));
            for (var s = 0; s < seconds; s++) current.Add(value);
        }

        if (current is { Count: > 0 }) stretches.Add(current);
        return Compute(stretches);
    }

    /// <summary>
    /// The same from the stored streams, for a ride read before best efforts existed. A 30 s gap is the pause
    /// floor the parser uses; it is enough to keep a stop from joining two efforts.
    /// </summary>
    public static int[] FromStreams(short?[]? power, IReadOnlyList<double> time)
    {
        if (power is null || power.Length == 0) return new int[Durations.Length];

        var stretches = new List<IReadOnlyList<double>>();
        List<double>? current = null;
        var count = Math.Min(power.Length, time.Count);
        for (var i = 0; i + 1 < count; i++)
        {
            var dt = time[i + 1] - time[i];
            if (dt <= 0) continue;
            if (dt > 30 || power[i] is not { } value)
            {
                if (current is { Count: > 0 }) stretches.Add(current);
                current = null;
                continue;
            }

            current ??= [];
            var seconds = Math.Max(1, (int)Math.Round(dt));
            for (var s = 0; s < seconds; s++) current.Add(value);
        }

        if (current is { Count: > 0 }) stretches.Add(current);
        return Compute(stretches);
    }

    private static bool CrossesPause(IReadOnlyList<PauseInterval>? pauses, double from, double to) =>
        pauses is not null && pauses.Any(p => p.StartS < to && p.EndS > from);
}
