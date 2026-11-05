using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed class BikeIdRequest
{
    public Guid Id { get; set; }
}

/// <summary>A bike with its parts and how worn each is. Someone else's bike looks like one that does not exist.</summary>
public sealed class GetBike(VelomineDbContext db, TimeProvider time) : Endpoint<BikeIdRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Get("bikes/{id}");
        Description(d => d.Produces<BikeDetailResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(BikeIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.AsNoTracking().Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.Id && b.UserId == userId, ct);
        if (bike is null) await Send.NotFoundAsync(ct);
        else await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, User.UserId(), time, ct), ct), ct);
    }
}
