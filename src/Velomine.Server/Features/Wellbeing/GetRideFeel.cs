using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Wellbeing;

public sealed class RideFeelRequest
{
    public Guid Id { get; set; }
}

/// <summary>The owner's RPE and note for one ride, if there is one.</summary>
public sealed class GetRideFeel(VelomineDbContext db) : Endpoint<RideFeelRequest, RideFeelResponse>
{
    public override void Configure()
    {
        Get("rides/{id}/feel");
        Description(d => d.Produces<RideFeelResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RideFeelRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var owner = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.Id)
            .Select(r => (Guid?)r.UserId)
            .FirstOrDefaultAsync(ct);
        if (owner is null || owner != userId)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var consented = await WellbeingRules.HasConsentAsync(db, userId, ct);
        var feel = await db.RideFeels.AsNoTracking().FirstOrDefaultAsync(f => f.RideId == req.Id, ct);
        await Send.OkAsync(new RideFeelResponse(
            !consented,
            consented ? feel?.Rpe : null,
            consented ? feel?.Notes : null), ct);
    }
}
