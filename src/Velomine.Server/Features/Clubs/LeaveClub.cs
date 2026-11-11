using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Clubs;

/// <summary>Leaves the club. An owner cannot leave: the instance admin moves ownership first.</summary>
public sealed class LeaveClub(VelomineDbContext db) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("club/leave");
        Description(d => d.Produces(204).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (membership.Role == ClubRoles.Owner)
        {
            AddError("The owner cannot leave the club. Ask the server admin to name another owner first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        db.ClubMemberships.Remove(membership);
        // Leaving revokes everything the member shared with that club.
        db.ShareGrants.RemoveRange(db.ShareGrants.Where(g => g.MemberId == userId));
        // The routes stay the member's own; only the share with this club ends.
        foreach (var route in await db.Routes.Where(r => r.UserId == userId && r.ClubId != null).ToListAsync(ct))
            route.ClubId = null;
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
