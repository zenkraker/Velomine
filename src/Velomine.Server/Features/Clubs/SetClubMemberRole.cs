using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class SetClubMemberRoleRequest
{
    /// <summary>From the address.</summary>
    public Guid UserId { get; set; }

    /// <summary>Either coach or member; ownership moves only from the admin pages.</summary>
    public required string Role { get; set; }
}

public sealed class SetClubMemberRoleValidator : Validator<SetClubMemberRoleRequest>
{
    public SetClubMemberRoleValidator() => RuleFor(x => x.Role)
        .NotEmpty()
        .Must(ClubRoles.Assignable.Contains)
        .WithMessage("Choose coach or member.");
}

/// <summary>An owner makes another member a coach, or puts a coach back to rider.</summary>
public sealed class SetClubMemberRole(VelomineDbContext db) : Endpoint<SetClubMemberRoleRequest, ClubMemberResponse>
{
    public override void Configure()
    {
        Put("club/members/{userId}/role");
        Description(d => d.Accepts<SetClubMemberRoleRequest>("application/json").Produces<ClubMemberResponse>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(SetClubMemberRoleRequest req, CancellationToken ct)
    {
        var mine = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == User.UserId(), ct);
        if (mine is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (mine.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        var target = await db.ClubMemberships.Include(m => m.User)
            .FirstOrDefaultAsync(m => m.ClubId == mine.ClubId && m.UserId == req.UserId, ct);
        if (target is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (target.Role == ClubRoles.Owner)
        {
            AddError("Ownership moves only from the admin pages.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        target.Role = req.Role;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(new ClubMemberResponse(target.UserId, target.User.DisplayName, target.Role, target.JoinedAt), ct);
    }
}
