using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class ClubRideIdRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>One ride with its meeting point, route, notes and who is in. Names stay inside the club.</summary>
public sealed class GetClubRide(VelomineDbContext db) : Endpoint<ClubRideIdRequest, ClubRideDetailResponse>
{
    public override void Configure()
    {
        Get("club/rides/{id}");
        Description(d => d.Produces<ClubRideDetailResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ClubRideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var ride = await CalendarQueries.RideAsync(db, membership.ClubId, req.Id, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(await CalendarQueries.DetailAsync(db, ride, userId, membership.Role, ct), ct);
    }
}
