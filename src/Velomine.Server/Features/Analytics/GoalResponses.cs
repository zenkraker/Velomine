using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

/// <summary>A goal with how far the current period has got. Percent is rounded down, so 99.9 % never reads as done.</summary>
public sealed record GoalResponse(
    Guid Id,
    string Period,
    string Metric,
    double Target,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    double Current,
    int Percent,
    bool Reached);

public static class GoalProgress
{
    public static async Task<GoalResponse[]> ForAsync(VelomineDbContext db, Guid userId, MemberClock clock, IReadOnlyList<Goal> goals, CancellationToken ct)
    {
        if (goals.Count == 0) return [];

        var starts = goals.ToDictionary(g => g.Id, g => Periods.StartOf(clock.Today, g.Period, clock.FirstDayOfWeek));
        var rides = await RideDays.LoadAsync(db, userId, clock, starts.Values.Min(), clock.Today.AddDays(1), ct);

        return [.. goals
            .OrderBy(g => Array.IndexOf(Periods.All, g.Period))
            .ThenBy(g => Array.IndexOf(GoalMetrics.All, g.Metric))
            .Select(g =>
            {
                var start = starts[g.Id];
                var current = GoalMetrics.Measure(g.Metric, [.. rides.Where(r => r.LocalDate >= start)]);
                return new GoalResponse(g.Id, g.Period, g.Metric, g.Target, start, Periods.Next(start, g.Period).AddDays(-1),
                    current, (int)Math.Floor(current / g.Target * 100), current >= g.Target);
            })];
    }
}
