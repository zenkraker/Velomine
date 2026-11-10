using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Every way in (password, second factor, single sign-on, refresh) ends here, so each signed-in device always has a
/// session row and the bearer token carries its id.
/// </summary>
public sealed class SessionSignIn(SignInManager<User> signIn, UserSessions sessions)
{
    public async Task SignInAsync(User user, string scheme, bool isPersistent, string? deviceLabel, CancellationToken ct)
    {
        var session = await sessions.CreateAsync(user.Id, deviceLabel, ct);
        await WriteAsync(user, scheme, isPersistent, session.Id, session.Generation);
    }

    /// <summary>Reissues the cookie or token pair after a refresh, with the generation the row now holds.</summary>
    public Task RotateAsync(User user, Guid sessionId, int generation, CancellationToken ct) =>
        WriteAsync(user, IdentityConstants.BearerScheme, isPersistent: false, sessionId, generation);

    private async Task WriteAsync(User user, string scheme, bool isPersistent, Guid sessionId, int generation)
    {
        signIn.AuthenticationScheme = scheme;
        await signIn.SignInWithClaimsAsync(user, isPersistent, SessionClaims.For(sessionId, generation));
    }
}
