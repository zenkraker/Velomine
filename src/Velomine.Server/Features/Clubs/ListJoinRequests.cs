using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>The owner's inbox: riders who asked to join this club, oldest first.</summary>
public sealed class ListJoinRequests(VelomineDbContext db) : EndpointWithoutRequest<JoinRequestsResponse>
{
    public override void Configure()
    {
        Get("club/join-requests");
        Description(d => d.Produces<JoinRequestsResponse>(200).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
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

        var requests = await db.ClubJoinRequests.AsNoTracking()
            .Where(r => r.ClubId == mine.ClubId)
            .OrderBy(r => r.CreatedAt)
            .Select(r => new JoinRequestResponse(r.Id, r.UserId, r.User.DisplayName, r.Note, r.CreatedAt))
            .ToListAsync(ct);

        await Send.OkAsync(new JoinRequestsResponse([.. requests]), ct);
    }
}
