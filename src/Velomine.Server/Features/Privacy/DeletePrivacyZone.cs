using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Privacy;

public sealed class DeletePrivacyZoneRequest
{
    public Guid Id { get; set; }
}

/// <summary>Removes one of the member's saved places. Someone else's zone looks like one that does not exist.</summary>
public sealed class DeletePrivacyZone(VelomineDbContext db) : Endpoint<DeletePrivacyZoneRequest>
{
    public override void Configure()
    {
        Delete("privacy/zones/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DeletePrivacyZoneRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var zone = await db.PrivacyZones.FirstOrDefaultAsync(z => z.Id == req.Id && z.UserId == userId, ct);
        if (zone is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        db.PrivacyZones.Remove(zone);
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
