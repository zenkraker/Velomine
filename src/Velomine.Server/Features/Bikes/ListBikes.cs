using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed record ListBikesResponse(BikeResponse[] Bikes);

/// <summary>The member's bikes, default first, then active ones, then archived.</summary>
public sealed class ListBikes(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ListBikesResponse>
{
    public override void Configure()
    {
        Get("bikes");
        Description(d => d.Produces<ListBikesResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var bikes = await db.Bikes.AsNoTracking().Where(b => b.UserId == userId)
            .OrderByDescending(b => b.IsDefault).ThenByDescending(b => b.IsActive).ThenBy(b => b.Name).ToListAsync(ct);
        await Send.OkAsync(new ListBikesResponse(await BikeQueries.SummariesAsync(db, bikes, await MemberClock.ForAsync(db, userId, time, ct), ct)), ct);
    }
}
