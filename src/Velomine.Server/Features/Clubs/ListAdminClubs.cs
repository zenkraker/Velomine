using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>Every club on the server, for the admin pages. Counts only, no member data.</summary>
public sealed class ListAdminClubs(VelomineDbContext db) : EndpointWithoutRequest<AdminClubListResponse>
{
    public override void Configure()
    {
        Get("admin/clubs");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<AdminClubListResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var clubs = await db.Clubs.AsNoTracking().OrderBy(c => c.Name).ToListAsync(ct);
        var list = new List<AdminClubResponse>(clubs.Count);
        foreach (var club in clubs) list.Add(await ClubQueries.AdminAsync(db, club, ct));
        await Send.OkAsync(new AdminClubListResponse([.. list]), ct);
    }
}
