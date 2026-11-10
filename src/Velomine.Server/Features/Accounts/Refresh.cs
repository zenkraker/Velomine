using FastEndpoints;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

public sealed record RefreshRequest(string RefreshToken);

/// <summary>
/// Trades a refresh token for a new pair. The token is single-use: the session row's generation rotates, so presenting
/// an older one again is treated as theft and ends that session.
/// </summary>
public sealed class Refresh(
    IOptionsMonitor<BearerTokenOptions> bearerOptions,
    SignInManager<User> signIn,
    UserManager<User> users,
    UserSessions sessions,
    SessionSignIn sessionSignIn,
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
        var options = bearerOptions.Get(IdentityConstants.BearerScheme);
        var ticket = options.RefreshTokenProtector.Unprotect(req.RefreshToken);

        if (ticket?.Properties.ExpiresUtc is not { } expires
            || clock.GetUtcNow() >= expires
            || await signIn.ValidateSecurityStampAsync(ticket.Principal) is not { } user
            || !await signIn.CanSignInAsync(user)
            || await users.IsLockedOutAsync(user)) // an admin locked the account: the session ends at its next renewal
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Tokens issued before sessions existed have no id; they are signed out once, at the release.
        if (ticket.Principal.SessionId() is not { } sessionId || ticket.Principal.SessionGeneration() is not { } generation)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var session = await sessions.FindAsync(sessionId, ct);
        if (session is null
            || session.UserId != user.Id
            || session.RevokedAt is not null
            || session.ExpiresAt <= clock.GetUtcNow())
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var next = await sessions.RotateAsync(sessionId, user.Id, generation, ct);
        if (next is null)
        {
            // The token was already spent: someone else has a copy. End the session rather than let both rotate.
            await sessions.RevokeAsync(sessionId, user.Id, ct);
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Writes the new access and refresh tokens as the response.
        await sessionSignIn.RotateAsync(user, sessionId, next.Value, ct);
    }
}
