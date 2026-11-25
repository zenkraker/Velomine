using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>
/// Writes the weeks a member is due: it loads what the planner reads, calls <see cref="WeekPlanner.Plan"/> and saves the
/// sessions it answers. Nothing else happens here — every choice the plan makes is the planner's, so it can be tested
/// without a database.
/// </summary>
public static class WeekPlanning
{
    /// <summary>
    /// This week from today, and on the week's last day next week too, so the rider sees the preview that evening. Only
    /// today and later days that are neither done nor moved are rewritten.
    /// </summary>
    public static async Task PlanAsync(
        VelomineDbContext db,
        User user,
        TrainingPlan plan,
        MemberClock clock,
        TimeProvider time,
        CancellationToken ct)
    {
        var weekStart = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        await WeekAsync(db, user, plan, clock, time, weekStart, clock.Today, ct);
        if (clock.Today == weekStart.AddDays(6))
            await WeekAsync(db, user, plan, clock, time, weekStart.AddDays(7), weekStart.AddDays(7), ct);
        plan.LastPlannedFor = clock.Today;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>Plans one week from <paramref name="from"/> and replaces the days the sweep may rewrite.</summary>
    private static async Task WeekAsync(
        VelomineDbContext db,
        User user,
        TrainingPlan plan,
        MemberClock clock,
        TimeProvider time,
        DateOnly weekStart,
        DateOnly from,
        CancellationToken ct)
    {
        var weekEnd = weekStart.AddDays(6);
        var historyFrom = weekStart.AddDays(-7 * WeekPlanner.NormalWeeksLookBack);
        var sessions = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id && s.LocalDate >= historyFrom && s.LocalDate <= weekEnd)
            .Select(s => new { s.LocalDate, s.State, s.Recipe, s.Minutes, s.QuestionRideId })
            .ToListAsync(ct);
        var rides = await RideDays.LoadAsync(db, user.Id, clock, historyFrom, weekEnd.AddDays(1), ct, ftpW: user.FtpW);
        // A rider back from a break longer than that window restarts from the week they really last rode, which sits
        // before it: that week is read too, so the gentle block is never left without the hours to restart from (W5).
        if (await LastWeekWithRidesAsync(db, clock, user.Id, historyFrom, ct) is { } lastRode)
            rides = [.. rides, .. await RideDays.LoadAsync(db, user.Id, clock, lastRode, lastRode.AddDays(7), ct, ftpW: user.FtpW)];
        var dayLoad = rides.GroupBy(r => r.LocalDate).ToDictionary(g => g.Key, g => g.Sum(r => r.Load));

        DateOnly WeekOf(DateOnly date) => Periods.StartOf(date, Periods.Week, clock.FirstDayOfWeek);
        var loadOfWeek = dayLoad
            .GroupBy(day => WeekOf(day.Key))
            .ToDictionary(g => g.Key, g => g.Sum(day => day.Value));
        var hoursOfWeek = rides
            .GroupBy(ride => WeekOf(ride.LocalDate))
            .ToDictionary(g => g.Key, g => g.Sum(ride => ride.MovingS) / 3600.0);

        var normal = WeekPlanner.NormalWeeks(loadOfWeek, weekStart, plan.LighterWeeks);
        // The same weeks, in the hours they really took: what the gentle base block restarts from after a break.
        var recentHours = WeekPlanner.NormalWeeks(hoursOfWeek, weekStart, plan.LighterWeeks);

        // The cycle counts the weeks it built since the last lighter week before this one.
        var previousLighter = plan.LighterWeeks.Where(start => start < weekStart).OrderByDescending(start => start).FirstOrDefault();
        var weeksSinceLighter = sessions
            .Select(s => WeekOf(s.LocalDate))
            .Distinct()
            .Count(start => start > previousLighter && start < weekStart);

        var lastWeek = sessions.Where(s => s.LocalDate >= weekStart.AddDays(-7) && s.LocalDate < weekStart).ToList();
        var lastWeekFullyDone = lastWeek.Count > 0
            && lastWeek.All(s => s.State is TrainingSessionStates.Done or TrainingSessionStates.Easy);

        // The last three completed mornings decide whether this week is lighter early (F2's rest band).
        var bands = new List<string>();
        for (var back = 1; back <= WeekPlanner.RestDaysInARow; back++)
            bands.Add((await Readiness.ForAsync(db, user.Id, clock, time, clock.Today.AddDays(-back), ct)).Band);

        var weekly = sessions.Where(s => s.LocalDate >= weekStart && s.LocalDate <= weekEnd).ToList();
        var fixedSessions = weekly
            // A session with a question of its own stays where it is: the rider is being asked about it by name.
            .Where(s => s.LocalDate < clock.Today || s.State != TrainingSessionStates.Planned || s.QuestionRideId is not null)
            .Select(s => new FixedSession(s.LocalDate, s.Recipe, s.Minutes, s.State))
            .ToArray();
        var storedDates = weekly.Select(s => s.LocalDate).ToHashSet();
        // A day ridden without a session is load the week has already spent, and the day is not planned again — today
        // included, because a ride before the sweep must not be written over.
        var spent = dayLoad
            .Where(day => day.Key >= weekStart && day.Key <= clock.Today && !storedDates.Contains(day.Key))
            .Select(day => new SpentDay(day.Key, Math.Round(day.Value, 1)))
            .ToArray();

        var goalHistory = await TrainingGoalSuggestion.ReadAsync(db, user.Id, clock, null, ct);
        var planned = WeekPlanner.Plan(new PlannerInput(
            Today: from,
            FirstDayOfWeek: clock.FirstDayOfWeek,
            FreeDays: plan.Days,
            LongRideDay: plan.LongRideDay,
            HoursPerWeek: plan.HoursPerWeek,
            Goal: plan.Goal,
            Age: user.BirthYear is { } year ? clock.Today.Year - year : null,
            History: new PlannerHistory(
                WeeksOfRides: goalHistory.WeeksOfRides,
                NormalWeekLoads: normal,
                WeeksSinceLighter: weeksSinceLighter,
                RecordedAsLighter: plan.LighterWeeks.Contains(weekStart),
                LastWeekFullyDone: lastWeekFullyDone,
                DaysSinceLastRide: goalHistory.DaysSinceLastRide == int.MaxValue ? null : goalHistory.DaysSinceLastRide,
                RecentReadinessBands: [.. bands],
                RecentNormalWeekHours: recentHours.Length > 0 ? recentHours.Average() : null),
            Fixed: fixedSessions,
            Spent: spent));

        // The days the sweep may rewrite: today and later, only where nothing is done or moved. They are removed rather
        // than deleted on the spot, so the deletes and the new sessions land in one save: a failure leaves the week it
        // found instead of an empty one.
        var rewritable = await db.TrainingSessions
            .Where(s => s.UserId == user.Id && s.LocalDate >= from && s.LocalDate <= weekEnd
                && s.State == TrainingSessionStates.Planned && s.QuestionRideId == null)
            .ToListAsync(ct);
        db.TrainingSessions.RemoveRange(rewritable);

        foreach (var session in planned.Sessions)
        {
            db.TrainingSessions.Add(new TrainingSession
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                LocalDate = session.LocalDate,
                Recipe = session.Recipe,
                Minutes = session.Minutes,
                BlockPercents = session.BlockPercents,
                State = TrainingSessionStates.Planned,
                CreatedAt = time.GetUtcNow(),
            });
        }

        if (planned.IsLighterWeek && !plan.LighterWeeks.Contains(weekStart))
        {
            plan.LighterWeeks = [.. plan.LighterWeeks.Append(weekStart)
                .Distinct().OrderByDescending(start => start).Take(WeekPlanner.NormalWeeksLookBack)];
        }
    }

    /// <summary>
    /// The start of the last week before <paramref name="before"/> with a ride: the week a rider back from a break last
    /// rode, which can sit before the window the mean reads.
    /// </summary>
    private static async Task<DateOnly?> LastWeekWithRidesAsync(
        VelomineDbContext db, MemberClock clock, Guid userId, DateOnly before, CancellationToken ct)
    {
        // A local date is at most a day from UTC's, so one day's margin catches every ride of the day before it.
        var utcBefore = new DateTimeOffset(before.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var last = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready
                && r.StartTime != null && r.StartTime < utcBefore)
            .OrderByDescending(r => r.StartTime)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes })
            .FirstOrDefaultAsync(ct);
        if (last?.StartTime is not { } start) return null;
        var local = clock.LocalDateOf(start, last.UtcOffsetMinutes);
        // A ride the window already reads is not a second read.
        return local < before ? Periods.StartOf(local, Periods.Week, clock.FirstDayOfWeek) : null;
    }
}

/// <summary>
/// The nightly planning as a sweep: every 15 minutes it plans every member whose own local date has passed the plan's
/// last-planned date, so a zone offset by :30 or :45 is planned on time and a run that was missed is caught up by the
/// next one. It runs only where background work is enabled, and only while the operator switch is on.
/// </summary>
public sealed class TrainingPlanSweeper(
    IServiceScopeFactory scopes,
    IOptions<TrainingOptions> options,
    ILogger<TrainingPlanSweeper> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(15);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogError(ex, "Planning the week failed unexpectedly.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    /// <summary>One sweep over the members whose plan is on and whose local date has passed the day it was written for.</summary>
    public async Task RunOnceAsync(CancellationToken ct)
    {
        // The operator's switch: off, nothing is planned and the stored plans stay exactly as they are.
        if (!options.Value.AutoEnabled) return;

        List<Guid> due;
        await using (var scope = scopes.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var time = scope.ServiceProvider.GetRequiredService<TimeProvider>();
            // A local date is at most a day from UTC's, so this reads every member whose day may have passed the plan's.
            var utcToday = DateOnly.FromDateTime(time.GetUtcNow().UtcDateTime);
            due = await db.TrainingPlans.AsNoTracking()
                .Where(p => p.IsOn && (p.LastPlannedFor == null || p.LastPlannedFor < utcToday.AddDays(2)))
                .Select(p => p.UserId)
                .ToListAsync(ct);
        }

        foreach (var userId in due)
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                await PlanOneAsync(
                    scope.ServiceProvider.GetRequiredService<VelomineDbContext>(),
                    scope.ServiceProvider.GetRequiredService<TimeProvider>(),
                    userId,
                    ct);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // One member's week never stops the rest: the next sweep tries that one again.
                logger.LogWarning("Could not plan one member's week ({Exception}).", ex.GetType().Name);
            }
        }
    }

    private static async Task PlanOneAsync(
        VelomineDbContext db, TimeProvider time, Guid userId, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId, ct);
        if (user is null || plan is null || !plan.IsOn) return;

        var clock = MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
        if (plan.LastPlannedFor is { } written && written >= clock.Today) return;
        await WeekPlanning.PlanAsync(db, user, plan, clock, time, ct);
    }
}
