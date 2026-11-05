using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

public sealed class GoalIdRequest
{
    public Guid Id { get; set; }
}

public sealed class DeleteGoal(VelomineDbContext db) : Endpoint<GoalIdRequest>
{
    public override void Configure()
    {
        Delete("analytics/goals/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(GoalIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var deleted = await db.Set<Goal>().Where(g => g.Id == req.Id && g.UserId == userId).ExecuteDeleteAsync(ct);
        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}
