using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Clubs;

public sealed class SetClubPlanRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>25, 75 or 150; leave out for no limit.</summary>
    public int? MemberLimit { get; set; }

    /// <summary>The last day the plan is paid for; leave out for no end.</summary>
    public DateOnly? PaidUntil { get; set; }
}

public sealed class SetClubPlanValidator : Validator<SetClubPlanRequest>
{
    public SetClubPlanValidator() =>
        RuleFor(x => x.MemberLimit)
            .Must(limit => limit is null || ClubPlan.Limits.Contains(limit.Value))
            .WithMessage($"The member limit is one of {string.Join(", ", ClubPlan.Limits)}, or none.");
}

/// <summary>
/// The server operator sets a club's size band and paid-until day. This is how a bank transfer is recorded today, and
/// where a payment provider will later write the same two values. A club's own owner cannot change their plan.
/// </summary>
public sealed class SetClubPlan(VelomineDbContext db) : Endpoint<SetClubPlanRequest, AdminClubResponse>
{
    public override void Configure()
    {
        Put("admin/clubs/{id}/plan");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<SetClubPlanRequest>("application/json").Produces<AdminClubResponse>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetClubPlanRequest req, CancellationToken ct)
    {
        if (await db.Clubs.FirstOrDefaultAsync(c => c.Id == req.Id, ct) is not { } club)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        club.MemberLimit = req.MemberLimit;
        club.PaidUntil = req.PaidUntil;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await ClubQueries.AdminAsync(db, club, ct), ct);
    }
}
