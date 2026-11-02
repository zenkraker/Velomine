using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>Deletes a bike and its parts. The rides stay, just without a bike. To keep the history, archive the bike instead.</summary>
public sealed class DeleteBike(VelomineDbContext db) : Endpoint<BikeIdRequest>
{
    public override void Configure()
    {
        Delete("bikes/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(BikeIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var deleted = await db.Bikes.Where(b => b.Id == req.Id && b.UserId == userId).ExecuteDeleteAsync(ct);
        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}
