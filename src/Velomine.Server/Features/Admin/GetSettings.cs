using FastEndpoints;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>SMTP as the server is set up. Read-only: it comes from environment variables, and the user name and password are never shown.</summary>
public sealed record SmtpStatus(bool Configured, string? Host, int? Port, string? Security, string? From);

/// <summary>Single sign-on as the server is set up. Read-only: it comes from environment variables, and the client id and secret are never shown.</summary>
public sealed record SsoStatus(bool Enabled, string? DisplayName, string? Authority);

/// <summary>The settings an admin can change, as they are in effect now, and the read-only status of what only the environment sets.</summary>
public sealed record SettingsResponse(
    bool SignUpEnabled,
    bool RequireAdminApproval,
    string? MapTileUrl,
    string? MapAttribution,
    SmtpStatus Smtp,
    SsoStatus Sso);

public sealed class GetSettings(SettingsReader settings, IOptions<SmtpOptions> smtp, IOptions<SsoOptions> sso)
    : EndpointWithoutRequest<SettingsResponse>
{
    public override void Configure()
    {
        Get("admin/settings");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<SettingsResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(await StatusAsync(settings, smtp.Value, sso.Value, ct), ct);

    public static async Task<SettingsResponse> StatusAsync(SettingsReader settings, SmtpOptions smtp, SsoOptions sso, CancellationToken ct)
    {
        var s = await settings.GetAsync(ct);
        return new SettingsResponse(
            s.SignUpEnabled,
            s.RequireAdminApproval,
            s.MapTileUrl,
            s.MapAttribution,
            smtp.Configured ? new SmtpStatus(true, smtp.Host, smtp.Port, smtp.Security, smtp.From) : new SmtpStatus(false, null, null, null, null),
            sso.Enabled ? new SsoStatus(true, sso.DisplayName, sso.Authority) : new SsoStatus(false, null, null));
    }
}
