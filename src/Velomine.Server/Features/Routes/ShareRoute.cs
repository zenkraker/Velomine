using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;

namespace Velomine.Server.Features.Routes;

/// <summary>Puts one of the member's own routes back in their club's library after it was withdrawn or removed.</summary>
public sealed class ShareRoute(VelomineDbContext db) : Endpoint<RouteIdRequest, RouteSummaryResponse>
{
    public override void Configure()
    {
        Post("routes/{id}/share");
        Description(d => d.Produces<RouteSummaryResponse>(200).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RouteIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await RouteQueries.ClubIdAsync(db, userId, ct) is not { } clubId)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

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

        route.ClubId = clubId;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(
            await RouteQueries.Summaries(db.Routes.AsNoTracking().Where(r => r.Id == route.Id), userId).FirstAsync(ct), ct);
    }
}

/// <summary>
/// Takes a route out of the club's library. The owner withdraws their own; the club's owner can remove anyone's. In
/// both cases the route stays with the member who added it, unshared. Everyone else cannot see the route: 404.
/// </summary>
public sealed class UnshareRoute(VelomineDbContext db) : Endpoint<RouteIdRequest>
{
    public override void Configure()
    {
        Delete("routes/{id}/share");
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RouteIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        var route = await RouteQueries.Visible(db, userId, membership?.ClubId).FirstOrDefaultAsync(r => r.Id == req.Id, ct);
        if (route is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (route.UserId != userId && membership?.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        route.ClubId = null;
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
