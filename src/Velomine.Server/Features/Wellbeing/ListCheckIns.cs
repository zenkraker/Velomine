using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Wellbeing;

public sealed class CheckInsRequest
{
    /// <summary>How many days to show, ending today: 7 to 366, default 30.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

public sealed class CheckInsValidator : Validator<CheckInsRequest>
{
    public CheckInsValidator() => RuleFor(x => x.Days).InclusiveBetween(7, 366).When(x => x.Days.HasValue);
}

/// <summary>The member's own check-ins over a range, newest last.</summary>
public sealed class ListCheckIns(VelomineDbContext db, TimeProvider time)
    : Endpoint<CheckInsRequest, CheckInsResponse>
{
    public override void Configure()
    {
        Get("wellbeing/check-ins");
        Description(d => d.Produces<CheckInsResponse>(200).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CheckInsRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (!await WellbeingRules.HasConsentAsync(db, userId, ct))
        {
            AddError("Accept the wellbeing terms first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var from = clock.Today.AddDays(-((req.Days ?? 30) - 1));
        var checkIns = await db.DailyCheckIns.AsNoTracking()
            .Where(c => c.UserId == userId && c.LocalDate >= from && c.LocalDate <= clock.Today)
            .OrderBy(c => c.LocalDate)
            .ToListAsync(ct);
        await Send.OkAsync(new CheckInsResponse([.. checkIns.Select(CheckInResponse.From)]), ct);
    }
}
