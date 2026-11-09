using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Wellbeing;

/// <summary>
/// Stops wellbeing processing and sharing. The check-ins and ride notes stay until the member deletes them
/// separately; nothing reads them once consent is gone.
/// </summary>
public sealed class WithdrawWellbeingConsent(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<WellbeingResponse>
{
    public override void Configure()
    {
        Delete("wellbeing/consent");
        Description(d => d.Produces<WellbeingResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        user.WellbeingConsentAt = null;
        user.WellbeingConsentVersion = null;

        var grants = await db.ShareGrants
            .Where(g => g.MemberId == userId && g.DataType == DataTypes.Wellbeing)
            .ToListAsync(ct);
        db.ShareGrants.RemoveRange(grants);
        await db.SaveChangesAsync(ct);

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var today = await db.DailyCheckIns.AsNoTracking()
            .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == clock.Today, ct);
        await Send.OkAsync(new WellbeingResponse(
            true,
            false,
            today is null ? null : CheckInResponse.From(today)), ct);
    }
}
