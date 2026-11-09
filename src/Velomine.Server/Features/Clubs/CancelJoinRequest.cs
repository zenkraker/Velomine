using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>The rider takes back their ask. The club is not told; there is nothing to answer.</summary>
public sealed class CancelJoinRequest(VelomineDbContext db) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Delete("club/join-request");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var request = await db.ClubJoinRequests.FirstOrDefaultAsync(r => r.UserId == User.UserId(), ct);
        if (request is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        db.ClubJoinRequests.Remove(request);
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
