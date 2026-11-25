using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Features.Coach;

/// <summary>
/// One planned session as a coach reads it: the day, the session in both languages, how it is going and, for a done
/// session, the minutes the ride took against the minutes planned. No targets, no score and no check-in.
/// </summary>
public sealed record CoachPlanSession(
    DateOnly LocalDate,
    string EnglishName,
    string ItalianName,
    int Minutes,
    string State,
    string? SkipReason,
    int? RiddenMinutes);

/// <summary>The rider's week as their coach reads it: the goal, the hours a week and one row per planned day.</summary>
public sealed record CoachPlanResponse(
    string Goal,
    int HoursPerWeek,
    DateOnly Start,
    DateOnly End,
    CoachPlanSession[] Sessions);

/// <summary>
/// The athlete's auto plan for this week, read-only, for a coach the athlete shares rides with. The rides grant must be
/// the coaches audience: a whole-club grant shows the plan to nobody, and a club role alone gives nothing. The score,
/// the make-easy reason and any check-in answer are never read here, so this cannot become a second, wider read of the
/// rider's own week. "Ill or injured" is health data and needs the wellbeing grant; the other reasons come with rides.
/// </summary>
public sealed class GetCoachPlan(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachAthleteRequest, CoachPlanResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/plan");
        Description(d => d.Produces<CoachPlanResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachAthleteRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(
                db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct, Audiences.Coaches))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var plan = await db.TrainingPlans.AsNoTracking().FirstOrDefaultAsync(p => p.UserId == req.UserId, ct);
        if (plan is null || !plan.IsOn)
        {
            // No plan is no card: the same answer as no grant, so the athlete page adds nothing either way.
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, req.UserId, time, ct);
        var start = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        var end = start.AddDays(6);
        var rows = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == req.UserId && s.LocalDate >= start && s.LocalDate <= end)
            .OrderBy(s => s.LocalDate)
            .ToListAsync(ct);
        var canWellbeing = await SharingRules.CanViewAsync(
            db, req.ClubId, viewerId, req.UserId, DataTypes.Wellbeing, ct);

        // Planned against done is the time alone: the card is time-only, as the story and the athlete page's mock-up
        // say. Training load and the ride's effort score stay off it.
        var rideIds = rows.Where(s => s.RideId is not null).Select(s => s.RideId!.Value).ToList();
        var ridden = await db.Rides.AsNoTracking()
            .Where(r => rideIds.Contains(r.Id))
            .Select(r => new { r.Id, r.MovingS })
            .ToDictionaryAsync(r => r.Id, r => r.MovingS, ct);

        var sessions = rows.Select(s =>
        {
            var recipe = Recipes.ByCode(s.Recipe);
            var reason = s.SkipReason == TrainingSkipReasons.Ill && !canWellbeing ? null : s.SkipReason;
            var minutes = s.RideId is { } id && ridden.TryGetValue(id, out var seconds) && seconds is { } riddenSeconds
                ? (int?)Math.Round(riddenSeconds / 60.0)
                : null;
            return new CoachPlanSession(
                s.LocalDate, recipe.EnglishName, recipe.ItalianName, s.Minutes, s.State, reason, minutes);
        }).ToArray();

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId, await CoachQueries.ViewerNameAsync(db, viewerId, ct),
            ViewKinds.Plan, ct);
        await Send.OkAsync(new CoachPlanResponse(plan.Goal, plan.HoursPerWeek, start, end, sessions), ct);
    }
}
