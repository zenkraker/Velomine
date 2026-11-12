using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Accounts;

public sealed record MeResponse(
    Guid Id,
    string Email,
    string DisplayName,
    string[] Roles,
    string? Language,
    bool TelemetryConsentRequired,
    bool TelemetryCrash,
    bool TelemetryUsage,
    string Units)
{
    public static MeResponse From(User user, IEnumerable<string> roles)
    {
        var required = user.TelemetryConsentVersion != TelemetryTerms.Version;
        return new MeResponse(
            user.Id,
            user.Email!,
            user.DisplayName,
            [.. roles],
            user.Language,
            required,
            !required && user.TelemetryCrash,
            !required && user.TelemetryUsage,
            user.Units);
    }
}

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
        await Send.OkAsync(MeResponse.From(user, roles), ct);
    }
}
