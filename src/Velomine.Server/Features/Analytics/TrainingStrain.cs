namespace Velomine.Server.Features.Analytics;

/// <summary>Foster's monotony and strain over one seven-day window, and the weeks it is compared with.</summary>
public sealed record StrainWindow(
    DateOnly From,
    DateOnly To,
    /// <summary>Mean over the population standard deviation of the seven daily loads, two decimals, capped at 7.</summary>
    double? Monotony,
    /// <summary>The week's load times the monotony, one decimal.</summary>
    double? Strain,
    /// <summary>The mean strain of the previous blocks that had load; null under four of them.</summary>
    double? Usual,
    /// <summary>Every day about as hard: monotony at or above 2.</summary>
    bool Monotonous,
    /// <summary>Strain above 1.5 times the usual week.</summary>
    bool HeavyWeek);

/// <summary>
/// Monotony and strain (Foster 1998): how alike the seven days are, and what the week cost. A week with no load has
/// neither. The previous eight seven-day blocks say what a usual week is; the window and the blocks shift together.
/// </summary>
public static class TrainingStrain
{
    public const int WindowDays = 7;

    public const int PreviousBlocks = 8;

    /// <summary>How many earlier blocks are needed before a week can be called heavy.</summary>
    public const int BlocksNeeded = 4;

    /// <summary>Foster's warning level for monotony.</summary>
    public const double WarnAt = 2.0;

    /// <summary>A week is heavy above this many times the usual one.</summary>
    public const double HeavyAt = 1.5;

    private const double MaxMonotony = 7.0;

    /// <summary>The window ending on <paramref name="end"/>, over each local day's load; a day without rides is 0.</summary>
    public static StrainWindow Compute(DateOnly end, IReadOnlyDictionary<DateOnly, double> loadByDate)
    {
        var from = end.AddDays(-(WindowDays - 1));
        var loads = DailyLoads(loadByDate, from);
        var monotony = Monotony(loads);
        var strain = monotony is { } m ? loads.Sum() * m : (double?)null;

        var blocks = new List<double>(PreviousBlocks);
        for (var block = 1; block <= PreviousBlocks; block++)
        {
            var blockLoads = DailyLoads(loadByDate, from.AddDays(-WindowDays * block));
            if (Monotony(blockLoads) is { } blockMonotony) blocks.Add(blockLoads.Sum() * blockMonotony);
        }
        var usual = blocks.Count >= BlocksNeeded ? blocks.Average() : (double?)null;

        return new StrainWindow(
            from,
            end,
            monotony,
            Round(strain, 1),
            Round(usual, 1),
            monotony >= WarnAt,
            strain is { } week && usual is { } mean && week > HeavyAt * mean);
    }

    private static double[] DailyLoads(IReadOnlyDictionary<DateOnly, double> loadByDate, DateOnly from) =>
        [.. Enumerable.Range(0, WindowDays).Select(i => loadByDate.GetValueOrDefault(from.AddDays(i)))];

    /// <summary>Mean over the population standard deviation; 7 when every day is equal, null in a week with no load.</summary>
    private static double? Monotony(IReadOnlyList<double> loads)
    {
        var weekly = loads.Sum();
        if (weekly <= 0) return null;
        var mean = weekly / loads.Count;
        var deviation = Math.Sqrt(loads.Sum(load => (load - mean) * (load - mean)) / loads.Count);
        return deviation <= 0 ? MaxMonotony : Math.Round(Math.Min(mean / deviation, MaxMonotony), 2);
    }

    private static double? Round(double? value, int digits) => value is { } number ? Math.Round(number, digits) : null;
}
