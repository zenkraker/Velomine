using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public sealed class RouteIdRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>
/// One route with its line. Visible to its owner and to the members of the club it is shared with, and to nobody
/// else: any other caller gets 404, like a route that does not exist. Opening a route is not a view of anyone's ride,
/// so it is not written to the sharing view log.
/// </summary>
public sealed class GetRoute(VelomineDbContext db) : Endpoint<RouteIdRequest, RouteDetailResponse>
{
    public override void Configure()
    {
        Get("routes/{id}");
        Description(d => d.Produces<RouteDetailResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RouteIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clubId = await RouteQueries.ClubIdAsync(db, userId, ct);
        var route = await RouteQueries.Visible(db, userId, clubId).AsNoTracking()
            .Include(r => r.Owner)
            .Include(r => r.Line)
            .FirstOrDefaultAsync(r => r.Id == req.Id, ct);
        if (route?.Line is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(RouteQueries.Detail(route, userId), ct);
    }
}
