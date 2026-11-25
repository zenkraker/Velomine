using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>
/// One session of a week with its targets: the day, the recipe as the rider reads it (never the R code alone), the day's
/// minutes, how it is going, and the numbers of each block from <see cref="SessionTargets"/>.
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
    bool HeartRateEstimated);

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
        var weekStart = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        var weeks = new List<TrainingWeek> { await OfWeekAsync(user, plan, weekStart, ct) };
        // A preview is what the last day's planning already wrote; the app shows its card that evening.
        if (clock.Today == weekStart.AddDays(6)) weeks.Add(await OfWeekAsync(user, plan, weekStart.AddDays(7), ct));

        await Send.OkAsync(new TrainingWeeksResponse([.. weeks]), ct);
    }

    /// <summary>
    /// A week as its sessions are stored: the targets are worked out here, never stored, because watts follow the FTP in
    /// use and heart rate the zone model in use.
    /// </summary>
    private async Task<TrainingWeek> OfWeekAsync(User user, TrainingPlan plan, DateOnly start, CancellationToken ct)
    {
        var end = start.AddDays(6);
        var rows = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id && s.LocalDate >= start && s.LocalDate <= end)
            .OrderBy(s => s.LocalDate)
            .ToListAsync(ct);

        var (max, threshold) = HeartRates.For(user, time);
        var hasPowerMeter = await db.Rides.AsNoTracking()
            .AnyAsync(r => r.UserId == user.Id && r.AvgPowerW != null, ct);

        var sessions = rows.Select(s =>
        {
            var recipe = Recipes.ByCode(s.Recipe);
            var targets = SessionTargets.For(recipe, s.Minutes, user.FtpW, threshold, hasPowerMeter);
            return new TrainingWeekSession(
                s.Id, s.LocalDate, s.Minutes, s.State, s.SkipReason, s.RideId,
                recipe.Code, recipe.TechnicalName, recipe.EnglishName, recipe.ItalianName,
                recipe.EnglishLine, recipe.ItalianLine,
                targets.Blocks, targets.Notes, targets.HeartRateEstimated);
        }).ToArray();

        // The planner records the weeks it made lighter, so the week says so whether it was planned today or a week ago.
        var lighter = rows.Count > 0 && plan.LighterWeeks.Contains(start);
        // The gentle block has no record of its own: a week of nothing but the base recipes is one, and it is never
        // named — the rider reads only that it gets more personal as their rides come in.
        var gentle = rows.Count > 0 && rows.All(s => WeekPlanner.BaseRecipes.Contains(s.Recipe));
        return new TrainingWeek(
            start,
            end,
            Math.Round(rows.Sum(s => PlannedScore(s.Recipe, s.Minutes)), 1),
            lighter,
            lighter ? TrainingNotes.EasyWeek : gentle ? TrainingNotes.MorePersonal : null,
            sessions);
    }

    /// <summary>A stored session's planned effort score: the recipe scaled to its day, as Story 2a's formula reads it.</summary>
    private static double PlannedScore(string recipe, int minutes) =>
        SessionPlan.PlannedScore(SessionPlan.For(Recipes.ByCode(recipe), minutes).Blocks);
}
