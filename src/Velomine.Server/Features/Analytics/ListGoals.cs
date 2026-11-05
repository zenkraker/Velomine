using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

public sealed record ListGoalsResponse(GoalResponse[] Goals);

public sealed class ListGoals(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ListGoalsResponse>
{
    public override void Configure()
    {
        Get("analytics/goals");
        Description(d => d.Produces<ListGoalsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var goals = await db.Set<Goal>().AsNoTracking().Where(g => g.UserId == userId).ToListAsync(ct);
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.OkAsync(new ListGoalsResponse(await GoalProgress.ForAsync(db, userId, clock, goals, ct)), ct);
    }
}
