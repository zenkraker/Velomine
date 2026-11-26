using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

/// <summary>One input to the readiness score. Keys are localized by the app; values and effects are numbers.</summary>
public sealed record ReadinessFactor(string Key, double Value, double Effect);

/// <summary>
/// Today's readiness. <see cref="Band"/> is "hard", "normal", "easy", "rest" or "unknown" when there is too little
/// history. The app turns the band and the factors into sentences, so the server never sends prose.
/// </summary>
public sealed record ReadinessResponse(
    DateOnly Date,
    int? Score,
    string Band,
    bool HasWellbeing,
    ReadinessFactor[] Factors);

/// <summary>
/// Today's readiness, which is <see cref="Readiness.ForAsync"/> for the member's own today: the planner and "make today
/// easy" read the same function, so the number cannot differ between the three.
/// </summary>
public sealed class GetReadiness(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<ReadinessResponse>
{
    public override void Configure()
    {
        Get("analytics/readiness");
        Description(d => d.Produces<ReadinessResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.OkAsync(await Readiness.ForAsync(db, userId, clock, time, clock.Today, ct), ct);
    }
}
