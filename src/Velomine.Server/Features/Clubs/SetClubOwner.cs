using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class SetClubOwnerRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>An account already in this club; it becomes the owner.</summary>
    public required Guid UserId { get; set; }
}

/// <summary>Moves ownership to another member, demoting the current owner to member. Used when an owner leaves.</summary>
public sealed class SetClubOwner(VelomineDbContext db) : Endpoint<SetClubOwnerRequest, AdminClubResponse>
{
    public override void Configure()
    {
        Put("admin/clubs/{id}/owner");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<SetClubOwnerRequest>("application/json").Produces<AdminClubResponse>(200).Produces(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetClubOwnerRequest req, CancellationToken ct)
    {
        if (await db.Clubs.FirstOrDefaultAsync(c => c.Id == req.Id, ct) is not { } club)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var memberships = await db.ClubMemberships.Where(m => m.ClubId == club.Id).ToListAsync(ct);
        var next = memberships.FirstOrDefault(m => m.UserId == req.UserId);
        if (next is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        foreach (var membership in memberships.Where(m => m.Role == ClubRoles.Owner && m.Id != next.Id))
            membership.Role = ClubRoles.Member;
        next.Role = ClubRoles.Owner;

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await ClubQueries.AdminAsync(db, club, ct), ct);
    }
}
