using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public sealed class RideRouteDraftRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>
/// The line of one of the member's own rides as the club would see it (see <see cref="RideRoutePoints"/>). The member
/// looks at it before confirming; nothing is saved here.
/// </summary>
public sealed class GetRideRouteDraft(VelomineDbContext db) : Endpoint<RideRouteDraftRequest, RouteDraftResponse>
{
    public override void Configure()
    {
        Get("rides/{id}/route-draft");
        Description(d => d.Produces<RouteDraftResponse>(200).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(RideRouteDraftRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        // Routes live in a club's library, so a rider with no club has nowhere to put one.
        if (await RouteQueries.ClubIdAsync(db, userId, ct) is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var ride = await RideRoutePoints.LoadAsync(db, userId, req.Id, ct);
        if (ride.Problem == RideRouteProblem.NotFound)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (ride.Problem != RideRouteProblem.None)
        {
            AddError(RideRoutePoints.Message(ride.Problem));
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(RouteQueries.Draft(Path.GetFileNameWithoutExtension(ride.FileName), ride.Points), ct);
    }
}
