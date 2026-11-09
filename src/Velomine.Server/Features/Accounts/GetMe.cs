using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed record MeResponse(Guid Id, string Email, string DisplayName, string[] Roles, string? Language);

public sealed class GetMe(UserManager<User> users) : EndpointWithoutRequest<MeResponse>
{
    public override void Configure() => Get("accounts/me");

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var roles = await users.GetRolesAsync(user);
        await Send.OkAsync(new MeResponse(user.Id, user.Email!, user.DisplayName, [.. roles], user.Language), ct);
    }
}
