using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

/// <summary>
/// Deletes a route for good. Only its owner may. A club ride that used the route stays and simply has no route.
/// </summary>
public sealed class DeleteRoute(VelomineDbContext db) : Endpoint<RouteIdRequest>
{
    public override void Configure()
    {
        Delete("routes/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RouteIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clubId = await RouteQueries.ClubIdAsync(db, userId, ct);
        var route = await RouteQueries.Visible(db, userId, clubId).FirstOrDefaultAsync(r => r.Id == req.Id, ct);
        if (route is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (route.UserId != userId)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        db.Routes.Remove(route);
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
