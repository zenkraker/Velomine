using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Supporter;

public sealed class SetSupporterHiddenRequest
{
    /// <summary>True hides the badge; the licence still counts.</summary>
    public required bool Hidden { get; set; }
}

/// <summary>Shows or hides the caller's own supporter badge. The licence is kept either way.</summary>
public sealed class SetSupporterHidden(VelomineDbContext db) : Endpoint<SetSupporterHiddenRequest, RiderLicenceResponse>
{
    public override void Configure()
    {
        Put("supporter/hidden");
        Description(d => d
            .Accepts<SetSupporterHiddenRequest>("application/json")
            .Produces<RiderLicenceResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .ProducesProblem(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetSupporterHiddenRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var licence = await db.SupporterLicences.FirstOrDefaultAsync(l => l.UserId == userId, ct);
        if (licence is null)
        {
            AddError("You do not have a supporter licence.");
            await Send.ErrorsAsync(404, ct);
            return;
        }

        licence.Hidden = req.Hidden;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(new RiderLicenceResponse(licence.Holder, licence.Serial, licence.ActivatedAt, licence.Hidden), ct);
    }
}
