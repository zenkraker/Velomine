using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>The reason a goal was suggested, as a code the app turns into its own sentence.</summary>
public static class TrainingGoalReasons
{
    public const string NotEnoughRiding = "not_enough_riding";
    public const string RegularRiding = "regular_riding";
    public const string EventSoon = "event_soon";
    public const string AfterBreak = "after_break";
    public const string PowerRides = "power_rides";
    public const string RegularRider = "regular_rider";
}

/// <summary>A suggested goal and the one-line reason for it.</summary>
public sealed record GoalSuggestion(string Goal, string Reason);

/// <summary>
/// What the rider's rides and events say, as the goal rules read it. Counts and sums, so a test states a known history
/// without building rides: the rules are in docs/training-models.md G1.
/// </summary>
public sealed record TrainingHistory(
    DateOnly Today,
    int WeeksOfRides,
    int RidesInLast4Weeks,
    double MinutesInLast4Weeks,
    int EmptyWeeksInLast4,
    int DaysSinceLastRide,
    int RidesInLast8Weeks,
    double HoursInLast8Weeks,
    int ActiveWeeksInLast8,
    bool RiderSetAnFtp,
    int RidesWithPowerInLast8Weeks,
    DateOnly? NextEventDate)
{
    /// <summary>No rides and no events: a rider who has just joined.</summary>
    public static TrainingHistory Empty(DateOnly today) =>
        new(today, 0, 0, 0, 4, int.MaxValue, 0, 0, 0, false, 0, null);
}

/// <summary>
/// The goal the setup pre-selects, from the rider's own rides. Velomine's own rules (docs/training-models.md G1): no
/// published rule picks a plan goal from ride history, so every threshold is ours and is marked as ours. The rider
/// always wins: this only pre-selects.
/// </summary>
public static class TrainingGoalSuggestion
{
    /// <summary>Fewer calendar weeks of rides than this is not enough to see a habit.</summary>
    public const int EnoughWeeks = 4;

    /// <summary>A regular rider, over the last four weeks.</summary>
    public const int RidesPerWeek = 2;

    public const int MinutesPerWeek = 150;

    /// <summary>Four weeks with two of them empty are not a habit either.</summary>
    public const int MostEmptyWeeks = 2;

    /// <summary>An event this close is what the rider is riding for (weeks, then days).</summary>
    public const int EventWeeks = 20;

    /// <summary>A break this long means "ease back in" rather than "build".</summary>
    public const int BreakDays = 10;

    /// <summary>An established rider, over the last eight weeks.</summary>
    public const int EstablishedWeeks = 26;

    public const int EstablishedRidesPerWeek = 3;

    public const int EstablishedHoursPerWeek = 4;

    public const int EstablishedActiveWeeks = 6;

    /// <summary>Half their recent rides carry power, and they have set an FTP: the one case for a power goal.</summary>
    public const double PowerShare = 0.5;

    /// <summary>The first rule that matches wins; the last one catches everyone else.</summary>
    public static GoalSuggestion For(TrainingHistory h)
    {
        if (h.WeeksOfRides < EnoughWeeks) return new(TrainingGoals.Aerobic, TrainingGoalReasons.NotEnoughRiding);

        if (h.RidesInLast4Weeks < RidesPerWeek * 4
            || h.MinutesInLast4Weeks < MinutesPerWeek * 4
            || h.EmptyWeeksInLast4 >= MostEmptyWeeks)
            return new(TrainingGoals.Aerobic, TrainingGoalReasons.RegularRiding);

        if (h.NextEventDate is { } eventDate && eventDate.DayNumber - h.Today.DayNumber <= EventWeeks * 7)
            return new(TrainingGoals.Event, TrainingGoalReasons.EventSoon);

        if (h.DaysSinceLastRide >= BreakDays) return new(TrainingGoals.Fitter, TrainingGoalReasons.AfterBreak);

        if (h.WeeksOfRides >= EstablishedWeeks
            && h.RidesInLast8Weeks >= EstablishedRidesPerWeek * 8
            && h.HoursInLast8Weeks >= EstablishedHoursPerWeek * 8
            && h.ActiveWeeksInLast8 >= EstablishedActiveWeeks
            && h.RiderSetAnFtp
            && h.RidesWithPowerInLast8Weeks >= h.RidesInLast8Weeks * PowerShare)
            return new(TrainingGoals.Faster, TrainingGoalReasons.PowerRides);

        return new(TrainingGoals.Fitter, TrainingGoalReasons.RegularRider);
    }

    /// <summary>
    /// The rider's rides and events as the rules read them, in the member's own calendar: a week starts on their first
    /// day of the week and a ride counts on its local date, as everywhere else.
    /// </summary>
    public static async Task<TrainingHistory> ReadAsync(
        VelomineDbContext db, Guid userId, MemberClock clock, DateOnly? nextEventDate, CancellationToken ct)
    {
        var ready = db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime != null);
        var today = clock.Today;
        // The history's length needs the first ride only, not the whole history: one row.
        var firstRide = await ready.OrderBy(r => r.StartTime)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes })
            .FirstOrDefaultAsync(ct);
        // The eight weeks the rules count, with a day's margin for the offset a ride carries.
        var since = new DateTimeOffset(today.AddDays(-(8 * 7 + 1)).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rides = await ready.Where(r => r.StartTime >= since)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes, r.MovingS, r.AvgPowerW })
            .ToListAsync(ct);
        var riderSetAnFtp = await db.Users.AsNoTracking()
            .AnyAsync(u => u.Id == userId && u.FtpW != null, ct);

        var local = rides
            .Select(r => new
            {
                Date = clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes),
                MovingS = r.MovingS ?? 0,
                HasPower = r.AvgPowerW != null,
            })
            .ToList();
        var first = firstRide is null
            ? (DateOnly?)null
            : clock.LocalDateOf(firstRide.StartTime!.Value, firstRide.UtcOffsetMinutes);

        // The weeks the rules count: this one and the three, or seven, before it. A date's own week start decides,
        // so a Saturday after today's weekday in the same calendar week is still last week.
        var todayStart = Periods.StartOf(today, Periods.Week, clock.FirstDayOfWeek);
        int WeekIndex(DateOnly date) =>
            (todayStart.DayNumber - Periods.StartOf(date, Periods.Week, clock.FirstDayOfWeek).DayNumber) / 7;

        var last4 = local.Where(r => WeekIndex(r.Date) < 4).ToList();
        var last8 = local.Where(r => WeekIndex(r.Date) < 8).ToList();
        return new TrainingHistory(
            Today: today,
            WeeksOfRides: first is { } f ? ((today.DayNumber - f.DayNumber) / 7) + 1 : 0,
            RidesInLast4Weeks: last4.Count,
            MinutesInLast4Weeks: last4.Sum(r => r.MovingS) / 60,
            EmptyWeeksInLast4: 4 - last4.Select(r => WeekIndex(r.Date)).Distinct().Count(),
            // The smallest distance back is the last ride; the largest would be the first one counted.
            DaysSinceLastRide: local.Count == 0 ? int.MaxValue : local.Min(r => today.DayNumber - r.Date.DayNumber),
            RidesInLast8Weeks: last8.Count,
            HoursInLast8Weeks: last8.Sum(r => r.MovingS) / 3600,
            ActiveWeeksInLast8: last8.Select(r => WeekIndex(r.Date)).Distinct().Count(),
            RiderSetAnFtp: riderSetAnFtp,
            RidesWithPowerInLast8Weeks: last8.Count(r => r.HasPower),
            NextEventDate: nextEventDate);
    }
}
