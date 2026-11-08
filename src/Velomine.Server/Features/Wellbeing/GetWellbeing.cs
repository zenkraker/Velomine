using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Wellbeing;

/// <summary>Whether the wellbeing terms were accepted, and today's check-in if there is one.</summary>
public sealed class GetWellbeing(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<WellbeingResponse>
{
    public override void Configure()
    {
        Get("wellbeing");
        Description(d => d.Produces<WellbeingResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.WellbeingConsentVersion })
            .FirstAsync(ct);
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var today = await db.DailyCheckIns.AsNoTracking()
            .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == clock.Today, ct);

        var consentRequired = user.WellbeingConsentVersion != WellbeingTerms.Version;
        await Send.OkAsync(new WellbeingResponse(
            consentRequired,
            !consentRequired,
            today is null ? null : CheckInResponse.From(today)), ct);
    }
}
