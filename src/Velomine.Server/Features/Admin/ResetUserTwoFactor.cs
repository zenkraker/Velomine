using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>
/// Clears a member's second factor when the phone and the recovery codes are both gone. Every session ends, so the
/// member signs in with the password and enrols again. Same trust model as the one-time password link.
/// </summary>
public sealed class ResetUserTwoFactor(UserManager<User> users, UserSessions sessions) : Endpoint<UserIdRequest>
{
    public override void Configure()
    {
        Post("admin/users/{id}/two-factor/reset");
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

        await users.SetTwoFactorEnabledAsync(user, false);
        await users.ResetAuthenticatorKeyAsync(user);
        await users.UpdateSecurityStampAsync(user);
        await sessions.RevokeAllAsync(user.Id, ct);
        await Send.NoContentAsync(ct);
    }
}
