using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Ends the browser's cookie. A bearer token is stateless and cannot be revoked here: the phone discards it and it
/// expires on its own (docs/rules/api.md).
/// </summary>
public sealed class Logout(SignInManager<User> signIn) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("accounts/logout");
        Description(d => d.Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await signIn.SignOutAsync();
        await Send.NoContentAsync(ct);
    }
}
