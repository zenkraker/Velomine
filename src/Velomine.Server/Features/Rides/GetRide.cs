using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class RideIdRequest
{
    public Guid Id { get; set; }
}

/// <summary>A member's own ride. Someone else's ride looks exactly like a ride that does not exist.</summary>
public sealed class GetRide(VelomineDbContext db) : Endpoint<RideIdRequest, RideResponse>
{
    public override void Configure() => Get("rides/{id}");

    public override async Task HandleAsync(RideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.AsNoTracking()
            .Include(r => r.Streams)
            .Include(r => r.Owner)
            .FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(RideDetails.Build(ride), ct);
    }
}
