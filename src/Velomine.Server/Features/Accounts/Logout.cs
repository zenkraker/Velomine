using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>Ends the current session: the row is revoked, so it leaves the member's list and stops renewing.</summary>
public sealed class Logout(SignInManager<User> signIn, UserSessions sessions) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("accounts/logout");
        Description(d => d.Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (User.SessionId() is { } session) await sessions.RevokeAsync(session, User.UserId(), ct);
        await signIn.SignOutAsync();
        await Send.NoContentAsync(ct);
    }
}
