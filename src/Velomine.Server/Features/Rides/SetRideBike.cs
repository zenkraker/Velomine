using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class SetRideBikeRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The bike that was ridden, or null for none. It must be one of the member's own bikes.</summary>
    public Guid? BikeId { get; set; }
}

public sealed class SetRideBike(VelomineDbContext db) : Endpoint<SetRideBikeRequest, RideResponse>
{
    public override void Configure()
    {
        Put("rides/{id}/bike");
        Description(d => d.Accepts<SetRideBikeRequest>("application/json").Produces<RideResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetRideBikeRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (req.BikeId is { } bikeId && !await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId, ct))
        {
            AddError(r => r.BikeId!, "That is not one of your bikes.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        ride.BikeId = req.BikeId;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(RideResponse.From(ride), ct);
    }
}
