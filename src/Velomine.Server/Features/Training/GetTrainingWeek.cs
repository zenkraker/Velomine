using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>
/// One session of a week with its targets: the day, the recipe as the rider reads it (never the R code alone), the day's
/// minutes, how it is going, and the numbers of each block from <see cref="SessionTargets"/>. A done session also
/// carries what its ride did and the score it earned (<see cref="SessionResult"/>), which is the rider's own.
/// </summary>
public sealed record TrainingWeekSession(
    Guid Id,
    DateOnly LocalDate,
    int Minutes,
    string State,
    string? SkipReason,
    Guid? RideId,
    string Recipe,
    string TechnicalName,
    string EnglishName,
    string ItalianName,
    string EnglishLine,
    string ItalianLine,
    BlockTarget[] Blocks,
    SessionNote[] Notes,
    bool HeartRateEstimated,
    /// <summary>The days it can move to, as the move sheet reads them: empty for a session that cannot move.</summary>
    MoveDay[] Move,
    /// <summary>Why the session was made easy (<see cref="TrainingEasyReasons"/>), or null when it never was.</summary>
    string? EasyReason = null,
    /// <summary>The day the replaced hard session went to, which the reason's line names; null when it was dropped.</summary>
    DateOnly? EasyMovedTo = null,
    /// <summary>Whether "make today easy" applies to it: today's session, still planned, a hard day or the long ride.</summary>
    bool CanMakeEasy = false,
    SessionResult? Result = null);

/// <summary>
/// The session a training notification is about, as the inbox reads it: the app words the sentence from the reason,
/// never from the check-in's own answers, which nobody but the owner ever receives.
/// </summary>
public sealed record TrainingSessionNotice(
    Guid SessionId,
    DateOnly LocalDate,
    int Minutes,
    string Recipe,
    string EnglishName,
    string ItalianName,
    string State,
    string? SkipReason,
    string? EasyReason,
    DateOnly? EasyMovedTo)
{
    public static TrainingSessionNotice Of(TrainingSession session)
    {
        var recipe = Recipes.ByCode(session.Recipe);
        return new(session.Id, session.LocalDate, session.Minutes, recipe.Code, recipe.EnglishName,
            recipe.ItalianName, session.State, session.SkipReason, session.EasyReason, session.EasyMovedTo);
    }
}

/// <summary>One week of the plan: its days, the load they plan and the one line the rider reads about it.</summary>
public sealed record TrainingWeek(
    DateOnly Start,
    DateOnly End,
    double PlannedLoad,
    bool IsLighterWeek,
    TrainingNote? Note,
    TrainingWeekSession[] Sessions);

/// <summary>
/// This week, and on its last day next week as the preview the rider sees that evening. The plan is keyed by the caller,
/// so there is no path to another member's week.
/// </summary>
public sealed record TrainingWeeksResponse(TrainingWeek[] Weeks);

/// <summary>
/// The rider's planned week. Owner only: the week is the caller's own plan, and a member with auto training off has no
/// week at all.
/// </summary>
public sealed class GetTrainingWeek(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<TrainingWeeksResponse>
{
    public override void Configure()
    {
        Get("training/week");
        Description(d => d.Produces<TrainingWeeksResponse>(200).Produces(404).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var plan = await db.TrainingPlans.AsNoTracking().FirstOrDefaultAsync(p => p.UserId == userId, ct);
        if (plan is null || !plan.IsOn)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var clock = MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
        await Send.OkAsync(await TrainingWeekView.OfAsync(db, user, plan, clock, time, ct), ct);
    }
}

/// <summary>
/// The weeks the app reads, built once for the endpoint that reads them and for every change to a session, so a change
/// answers exactly what the week would answer afterwards and the app never asks twice.
/// </summary>
public static class TrainingWeekView
{
    /// <summary>This week, and on its last day next week as the preview the rider sees that evening.</summary>
    public static async Task<TrainingWeeksResponse> OfAsync(
        VelomineDbContext db, User user, TrainingPlan plan, MemberClock clock, TimeProvider time, CancellationToken ct)
    {
        var weekStart = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        var weeks = new List<TrainingWeek> { await OfWeekAsync(db, user, plan, clock, time, weekStart, ct) };
        // A preview is what the last day's planning already wrote; the app shows its card that evening.
        if (clock.Today == weekStart.AddDays(6))
            weeks.Add(await OfWeekAsync(db, user, plan, clock, time, weekStart.AddDays(7), ct));
        return new TrainingWeeksResponse([.. weeks]);
    }

    /// <summary>
    /// A week as its sessions are stored: the targets are worked out here, never stored, because watts follow the FTP in
    /// use and heart rate the zone model in use.
    /// </summary>
    private static async Task<TrainingWeek> OfWeekAsync(
        VelomineDbContext db, User user, TrainingPlan plan, MemberClock clock, TimeProvider time, DateOnly start,
        CancellationToken ct)
    {
        var end = start.AddDays(6);
        var rows = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id && s.LocalDate >= start && s.LocalDate <= end)
            .OrderBy(s => s.LocalDate)
            .ToListAsync(ct);

        var (max, threshold) = HeartRates.For(user, time);
        var hasPowerMeter = await db.Rides.AsNoTracking()
            .AnyAsync(r => r.UserId == user.Id && r.AvgPowerW != null, ct);
        // The score of every session a ride did, worked out here and never stored (L8).
        var results = await SessionScore.ForAsync(db, rows, user, time, ct);
        // The days each session can move to, and the days around the week a hard day is kept apart from: the days
        // either side belong to the weeks next to this one.
        var around = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id && s.LocalDate >= start.AddDays(-1) && s.LocalDate <= end.AddDays(1))
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(ct);

        var sessions = rows.Select(s =>
        {
            var recipe = Recipes.ByCode(s.Recipe);
            var targets = SessionTargets.For(recipe, s.Minutes, user.FtpW, threshold, hasPowerMeter);
            // The move sheet offers every day left this week; a session already ridden, skipped or missed stays put.
            var movable = s.LocalDate >= clock.Today
                && s.State is TrainingSessionStates.Planned or TrainingSessionStates.Moved;
            return new TrainingWeekSession(
                s.Id, s.LocalDate, s.Minutes, s.State, s.SkipReason, s.RideId,
                recipe.Code, recipe.TechnicalName, recipe.EnglishName, recipe.ItalianName,
                recipe.EnglishLine, recipe.ItalianLine,
                targets.Blocks, targets.Notes, targets.HeartRateEstimated,
                Move: movable ? SessionAdaptation.Days(around, s, clock) : [],
                EasyReason: s.EasyReason,
                EasyMovedTo: s.EasyMovedTo,
                CanMakeEasy: s.LocalDate == clock.Today && s.State == TrainingSessionStates.Planned
                    && SessionAdaptation.IsReplacedByEasy(s.Recipe),
                Result: results.GetValueOrDefault(s.Id));
        }).ToArray();

        // The planner records the weeks it made lighter, so the week says so whether it was planned today or a week ago.
        var lighter = rows.Count > 0 && plan.LighterWeeks.Contains(start);
        // The gentle block has no record of its own: every day from today on is one of the base recipes. The days before
        // today are not read, so a break that began mid-week still shows the line for the rest of the week.
        var gentle = rows.Any(s => s.LocalDate >= clock.Today)
            && rows.All(s => s.LocalDate < clock.Today || WeekPlanner.BaseRecipes.Contains(s.Recipe));
        var planned = rows.Sum(s => PlannedScore(s.Recipe, s.Minutes));
        var spent = await SpentLoadAsync(db, user, clock, rows, start, end, ct);
        return new TrainingWeek(
            start,
            end,
            Math.Round(planned + spent, 1),
            lighter,
            lighter ? TrainingNotes.EasyWeek : gentle ? TrainingNotes.MorePersonal : null,
            sessions);
    }

    /// <summary>
    /// What the week has already spent: a ride on a day it has no session for is load the week carries, as the planner
    /// counts it, so the load the rider reads and the load the planner budgets against are the same number.
    /// </summary>
    private static async Task<double> SpentLoadAsync(
        VelomineDbContext db, User user, MemberClock clock, List<TrainingSession> rows, DateOnly start, DateOnly end,
        CancellationToken ct)
    {
        var stored = rows.Select(s => s.LocalDate).ToHashSet();
        var rides = await RideDays.LoadAsync(db, user.Id, clock, start, end.AddDays(1), ct, ftpW: user.FtpW);
        return rides
            .Where(ride => ride.LocalDate <= clock.Today && !stored.Contains(ride.LocalDate))
            .Sum(ride => ride.Load);
    }

    /// <summary>A stored session's planned effort score: the recipe scaled to its day, as Story 2a's formula reads it.</summary>
    private static double PlannedScore(string recipe, int minutes) => SessionPlan.PlannedScore(recipe, minutes);
}
