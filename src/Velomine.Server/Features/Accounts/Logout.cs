using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>Ends a cookie session. Bearer tokens just expire.</summary>
public sealed class Logout(SignInManager<User> signIn) : EndpointWithoutRequest
{
    public override void Configure() => Post("accounts/logout");

    public override async Task HandleAsync(CancellationToken ct)
    {
        await signIn.SignOutAsync();
        await Send.NoContentAsync(ct);
    }
}
