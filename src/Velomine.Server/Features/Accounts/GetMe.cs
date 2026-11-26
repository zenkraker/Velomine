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
    string Units,
    string? RiderMode,
    bool? RiderModeSupported)
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
            user.Units,
            user.RiderMode,
            // Nullable on purpose: an older server does not send it, so an app can tell "no rider modes" from
            // "not chosen yet" without waiting for a save to fail. A new server always says true.
            RiderModeSupported: true);
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
