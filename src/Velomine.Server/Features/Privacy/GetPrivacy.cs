using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Privacy;

/// <summary>The member's own privacy choices: stream switches, trimming and saved zones.</summary>
public sealed class GetPrivacy(VelomineDbContext db) : EndpointWithoutRequest<PrivacyResponse>
{
    public override void Configure()
    {
        Get("privacy");
        Description(d => d.Produces<PrivacyResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var settings = await db.PrivacySettings.AsNoTracking().FirstOrDefaultAsync(s => s.UserId == userId, ct);
        var zones = await db.PrivacyZones.AsNoTracking()
            .Where(z => z.UserId == userId)
            .OrderBy(z => z.Name)
            .ToListAsync(ct);
        await Send.OkAsync(PrivacyResponse.From(settings, zones), ct);
    }
}
