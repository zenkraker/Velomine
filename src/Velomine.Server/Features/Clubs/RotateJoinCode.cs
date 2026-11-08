using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>Gives the club a new join code; the old link stops working at once.</summary>
public sealed class RotateJoinCode(VelomineDbContext db) : EndpointWithoutRequest<JoinCodeResponse>
{
    public override void Configure()
    {
        Post("club/join-code");
        Description(d => d.Produces<JoinCodeResponse>(200).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var membership = await db.ClubMemberships.Include(m => m.Club)
            .FirstOrDefaultAsync(m => m.UserId == User.UserId(), ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (membership.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        membership.Club.JoinCode = await JoinCodes.UniqueAsync(db, ct);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(new JoinCodeResponse(membership.Club.JoinCode), ct);
    }
}
