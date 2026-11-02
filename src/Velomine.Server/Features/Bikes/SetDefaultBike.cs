using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>Makes this the bike new rides are given at import. Old rides are not touched. An archived bike cannot be the default.</summary>
public sealed class SetDefaultBike(VelomineDbContext db) : Endpoint<BikeIdRequest>
{
    public override void Configure()
    {
        Post("bikes/{id}/default");
        Description(d => d.Produces(204).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(BikeIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.FirstOrDefaultAsync(b => b.Id == req.Id && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (!bike.IsActive)
        {
            ThrowError("An archived bike cannot be the default.");
            return;
        }

        // The unique index allows one default, so clear the old one first and do both in one transaction.
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        await db.Bikes.Where(b => b.UserId == userId && b.IsDefault && b.Id != bike.Id).ExecuteUpdateAsync(s => s.SetProperty(b => b.IsDefault, false), ct);
        bike.IsDefault = true;
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
