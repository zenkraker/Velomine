using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

public sealed class DeclineJoinRequestRequest
{
    /// <summary>From the address.</summary>
    public Guid JoinRequestId { get; set; }
}

/// <summary>The owner says no. The rider is told, without the reason.</summary>
public sealed class DeclineJoinRequest(VelomineDbContext db, TimeProvider time)
    : Endpoint<DeclineJoinRequestRequest>
{
    public override void Configure()
    {
        Post("club/join-requests/{joinRequestId}/decline");
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DeclineJoinRequestRequest req, CancellationToken ct)
    {
        var mine = await db.ClubMemberships.AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == User.UserId(), ct);
        if (mine is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (mine.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        var request = await db.ClubJoinRequests
            .Include(r => r.Club)
            .FirstOrDefaultAsync(r => r.Id == req.JoinRequestId && r.ClubId == mine.ClubId, ct);
        if (request is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        db.ClubJoinRequests.Remove(request);
        Notify.Add(db, time, request.UserId, NotificationTypes.ClubJoinDeclined, request.Club.Name);
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
