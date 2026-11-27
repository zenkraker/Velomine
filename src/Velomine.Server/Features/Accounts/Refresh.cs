using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

public sealed record RefreshRequest(string RefreshToken);

/// <summary>
/// Trades a refresh token for a new pair, as Identity's own /refresh does: the token must be ours, unexpired and still
/// carry the account's security stamp. The account must also still be allowed to sign in.
/// </summary>
public sealed class Refresh(
    IOptionsMonitor<BearerTokenOptions> bearerOptions,
    SignInManager<User> signIn,
    UserManager<User> users,
    TimeProvider clock) : Endpoint<RefreshRequest>
{
    public override void Configure()
    {
        Post("accounts/refresh");
        AllowAnonymous();
        Description(d => d.Accepts<RefreshRequest>("application/json").Produces<TokenResponse>(200, "application/json").Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(RefreshRequest req, CancellationToken ct)
    {
        var ticket = bearerOptions.Get(IdentityConstants.BearerScheme).RefreshTokenProtector.Unprotect(req.RefreshToken);

        if (ticket?.Properties.ExpiresUtc is not { } expires
            || clock.GetUtcNow() >= expires
            || await signIn.ValidateSecurityStampAsync(ticket.Principal) is not { } user
            || !await signIn.CanSignInAsync(user)
            || await users.IsLockedOutAsync(user))
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Writes the new access and refresh tokens as the response.
        await HttpContext.SignInAsync(IdentityConstants.BearerScheme, await signIn.CreateUserPrincipalAsync(user));
    }
}
