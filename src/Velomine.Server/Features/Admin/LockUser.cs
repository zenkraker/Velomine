using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

public sealed class UserIdRequest
{
    public Guid Id { get; set; }
}

/// <summary>
/// Locks an account: it cannot sign in, and its sessions stop renewing (an access token already issued still works until
/// it expires, at most an hour). Nothing is deleted. Unlock brings it back as it was.
/// </summary>
public sealed class LockUser(UserManager<User> users) : Endpoint<UserIdRequest>
{
    public override void Configure()
    {
        Post("admin/users/{id}/lock");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(UserIdRequest req, CancellationToken ct)
    {
        if (await users.FindByIdAsync(req.Id.ToString()) is not { } user)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (user.Id == User.UserId())
        {
            AddError("You cannot lock your own account.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await users.SetLockoutEnabledAsync(user, true);
        await users.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);
        await users.UpdateSecurityStampAsync(user); // signed-in browsers and renewable sessions stop being valid
        await Send.NoContentAsync(ct);
    }
}

public sealed class UnlockUser(UserManager<User> users) : Endpoint<UserIdRequest>
{
    public override void Configure()
    {
        Post("admin/users/{id}/unlock");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UserIdRequest req, CancellationToken ct)
    {
        if (await users.FindByIdAsync(req.Id.ToString()) is not { } user)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await users.SetLockoutEndDateAsync(user, null);
        await users.ResetAccessFailedCountAsync(user);
        await Send.NoContentAsync(ct);
    }
}
