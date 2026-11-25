using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Features.Demo;

/// <summary>One day of the demo rider's week: the recipe it was planned with and the minutes it gets.</summary>
public sealed record DemoSessionDay(DateOnly LocalDate, string Recipe, int Minutes);

/// <summary>The setup the demo rider's week is written with, and the sessions it starts with.</summary>
public sealed record DemoWeek(int[] Days, int HoursPerWeek, int LongRideDay, DemoSessionDay[] Sessions);

/// <summary>
/// The demo rider's week, worked out from today alone: the days the seed plans, which of them is the long ride and
/// which are hard, and the recipe and the minutes of each session. The week is stored the way the planner stores one —
/// a recipe and the day's minutes — so its block percentages and its effort score come from <see cref="SessionPlan"/>
/// when it is read, never from here.
/// </summary>
public static class DemoTrainingWeek
{
    public static DemoWeek For(DateOnly today, DayOfWeek firstDayOfWeek, string goal)
    {
        var weekEnd = Periods.StartOf(today, Periods.Week, firstDayOfWeek).AddDays(6);
        // The three days behind today come with it, so the week always has sessions that are over: the rides the script
        // wrote are theirs and the day between them is the one it left out.
        var first = today.AddDays(-3);
        var week = Enumerable.Range(0, weekEnd.DayNumber - first.DayNumber + 1).Select(first.AddDays).ToArray();

        // The long ride is the weekend's, and the rider's own long-ride day when today is the weekend (the planner's rule).
        var longRide = today.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday ? today : LastWeekendDay(week);
        // One day of the week is a rest day, so a visitor finds a day to move a session to.
        var rest = new[] { today.AddDays(3), today.AddDays(1) }
            .FirstOrDefault(day => day != longRide && day <= weekEnd);
        var days = week.Where(day => day != rest).ToArray();
        // An hour a day and two for the long ride.
        var hours = Math.Clamp(days.Length + WeekPlanner.LongRideShares - 1, 1, 30);

        // The goal's own hard sessions, never two days running and never beside the long ride (W1).
        var preferences = WeekPlanner.QualityPreferences(goal);
        var hard = new List<DateOnly>();
        foreach (var candidate in new[] { today, today.AddDays(-3), today.AddDays(2) })
        {
            if (preferences.Length == 0 || hard.Count >= WeekPlanner.HardDays(hours, goal)) break;
            if (!days.Contains(candidate) || candidate == longRide) continue;
            if (Math.Abs(candidate.DayNumber - longRide.DayNumber) == 1) continue;
            if (hard.Any(day => Math.Abs(day.DayNumber - candidate.DayNumber) == 1)) continue;
            hard.Add(candidate);
        }

        var hardAndLong = hard.Append(longRide).ToArray();
        string RecipeOf(DateOnly day) =>
            day == longRide ? "R03"
            : hard.Contains(day) ? preferences[0]
            : hardAndLong.Any(h => Math.Abs(h.DayNumber - day.DayNumber) == 1) ? "R01"
            : "R02";

        // The week's minutes on its days: the long ride takes two shares and every other day one, as the planner's do.
        var budget = hours * 60;
        var share = budget / (days.Length + WeekPlanner.LongRideShares - 1);
        var minutes = days
            .Select(day => Math.Max(day == longRide ? share * WeekPlanner.LongRideShares : share, WeekPlanner.MinimumDayMinutes))
            .ToArray();
        var longIndex = Array.IndexOf(days, longRide);
        minutes[longIndex] = Math.Max(minutes[longIndex] + budget - minutes.Sum(), WeekPlanner.MinimumDayMinutes);

        return new DemoWeek(
            [.. days.Select(day => (int)day.DayOfWeek).Distinct().Order()],
            hours,
            (int)longRide.DayOfWeek,
            [.. days.Select((day, i) => new DemoSessionDay(day, RecipeOf(day), minutes[i]))]);
    }

    /// <summary>The long ride's day for a week that holds no weekend day the rider is free on: the last day it holds.</summary>
    private static DateOnly LastWeekendDay(DateOnly[] week)
    {
        foreach (var weekend in new[] { DayOfWeek.Sunday, DayOfWeek.Saturday })
        {
            var day = week.LastOrDefault(d => d.DayOfWeek == weekend);
            if (day != default) return day;
        }

        return week[^1];
    }
}
