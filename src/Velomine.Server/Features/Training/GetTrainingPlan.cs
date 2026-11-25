using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Training;

/// <summary>
/// The rider's auto-training setup: the answers given last time, or the suggested goal when there are none. Days and
/// the long-ride day are the API's day names; <see cref="LongRideDay"/> null is "Velomine picks". The two heart-rate
/// fields are the numbers in use, with where each came from, so the setup opens on the right side of "I don't know".
/// </summary>
public sealed record TrainingPlanResponse(
    bool On,
    string? Goal,
    string SuggestedGoal,
    string SuggestionReason,
    string[] Days,
    int? HoursPerWeek,
    string? LongRideDay,
    DateOnly? LastPlannedFor,
    int? MaxHeartRate,
    string? MaxHeartRateSource,
    int? BirthYear,
    string? NextEventName,
    DateOnly? NextEventDate);

/// <summary>One builder for the plan response, so reading it and saving it answer the same shape.</summary>
public static class TrainingPlanView
{
    public static async Task<TrainingPlanResponse> OfAsync(
        VelomineDbContext db, User user, MemberClock clock, TimeProvider time, CancellationToken ct)
    {
        var plan = await db.TrainingPlans.AsNoTracking().FirstOrDefaultAsync(p => p.UserId == user.Id, ct);
        var nextEvent = await db.Events.AsNoTracking()
            .Where(e => e.UserId == user.Id && e.Date >= clock.Today)
            .OrderBy(e => e.Date).ThenBy(e => e.Id)
            .Select(e => new { e.Name, e.Date })
            .FirstOrDefaultAsync(ct);
        var history = await TrainingGoalSuggestion.ReadAsync(db, user.Id, clock, nextEvent?.Date, ct);
        var suggestion = TrainingGoalSuggestion.For(history);
        var max = HeartRates.For(user, time).Max;
        return new TrainingPlanResponse(
            On: plan?.IsOn ?? false,
            Goal: plan?.Goal,
            SuggestedGoal: suggestion.Goal,
            SuggestionReason: suggestion.Reason,
            Days: [.. (plan?.Days ?? []).Select(d => WeekDays.Name((DayOfWeek)d))],
            HoursPerWeek: plan?.HoursPerWeek,
            LongRideDay: plan?.LongRideDay is { } day ? WeekDays.Name((DayOfWeek)day) : null,
            LastPlannedFor: plan?.LastPlannedFor,
            MaxHeartRate: max?.Bpm,
            MaxHeartRateSource: max?.Source,
            BirthYear: user.BirthYear,
            NextEventName: nextEvent?.Name,
            NextEventDate: nextEvent?.Date);
    }
}

/// <summary>
/// The setup as it was answered last time and the goal Velomine suggests. It is the member's own plan and nobody
/// else's: the plan is keyed by the caller, so there is no path to another member's.
/// </summary>
public sealed class GetTrainingPlan(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<TrainingPlanResponse>
{
    public override void Configure()
    {
        Get("training/plan");
        Description(d => d.Produces<TrainingPlanResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.OkAsync(await TrainingPlanView.OfAsync(db, user, clock, time, ct), ct);
    }
}
