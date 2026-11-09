using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

public sealed class SetUserRolesRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>Any of member, coach and admin. Member is always kept.</summary>
    public required string[] Roles { get; set; }
}

public sealed class SetUserRolesValidator : Validator<SetUserRolesRequest>
{
    public SetUserRolesValidator() =>
        RuleFor(x => x.Roles).NotNull().Must(r => r.All(Accounts.Roles.All.Contains)).WithMessage("Choose from: " + string.Join(", ", Accounts.Roles.All) + ".");
}

public sealed class SetUserRoles(UserManager<User> users) : Endpoint<SetUserRolesRequest, AdminUserSummary>
{
    public override void Configure()
    {
        Put("admin/users/{id}/roles");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<SetUserRolesRequest>("application/json").Produces<AdminUserSummary>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(SetUserRolesRequest req, CancellationToken ct)
    {
        if (await users.FindByIdAsync(req.Id.ToString()) is not { } user)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var wanted = req.Roles.Append(Accounts.Roles.Member).Distinct().ToArray();
        var current = await users.GetRolesAsync(user);

        // An admin cannot take their own admin role away, which also means there is always at least one admin left.
        if (user.Id == User.UserId() && current.Contains(Accounts.Roles.Admin) && !wanted.Contains(Accounts.Roles.Admin))
        {
            AddError("You cannot remove your own admin role. Ask another admin.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await users.RemoveFromRolesAsync(user, current.Except(wanted));
        await users.AddToRolesAsync(user, wanted.Except(current));
        // A changed role must take effect now: old cookies and access tokens still carry the previous claims.
        await users.UpdateSecurityStampAsync(user);

        await Send.OkAsync(new AdminUserSummary(user.Id, user.Email!, user.DisplayName, user.IsApproved,
            await users.IsLockedOutAsync(user), [.. (await users.GetRolesAsync(user)).Order()], user.CreatedAt), ct);
    }
}
