using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Wellbeing;

public sealed record WellbeingConsentRequest(bool Accepted);

public sealed class WellbeingConsentValidator : Validator<WellbeingConsentRequest>
{
    public WellbeingConsentValidator() =>
        RuleFor(x => x.Accepted).Must(accepted => accepted).WithMessage("Accept the wellbeing terms to continue.");
}

/// <summary>Records that the member accepted the current wellbeing terms, before any check-in is stored.</summary>
public sealed class GiveWellbeingConsent(VelomineDbContext db, TimeProvider time)
    : Endpoint<WellbeingConsentRequest, WellbeingResponse>
{
    public override void Configure()
    {
        Post("wellbeing/consent");
        Description(d => d.Accepts<WellbeingConsentRequest>("application/json").Produces<WellbeingResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(WellbeingConsentRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        user.WellbeingConsentAt = time.GetUtcNow();
        user.WellbeingConsentVersion = WellbeingTerms.Version;
        await db.SaveChangesAsync(ct);

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var today = await db.DailyCheckIns.AsNoTracking()
            .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == clock.Today, ct);
        await Send.OkAsync(new WellbeingResponse(
            false,
            true,
            today is null ? null : CheckInResponse.From(today)), ct);
    }
}
