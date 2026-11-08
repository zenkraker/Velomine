using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Wellbeing;

/// <summary>Removes the owner's RPE and note for one ride.</summary>
public sealed class DeleteRideFeel(VelomineDbContext db) : Endpoint<RideFeelRequest>
{
    public override void Configure()
    {
        Delete("rides/{id}/feel");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RideFeelRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var owned = await db.Rides.AsNoTracking().AnyAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (!owned)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var feel = await db.RideFeels.FirstOrDefaultAsync(f => f.RideId == req.Id, ct);
        if (feel is not null)
        {
            db.RideFeels.Remove(feel);
            await db.SaveChangesAsync(ct);
        }

        await Send.NoContentAsync(ct);
    }
}
