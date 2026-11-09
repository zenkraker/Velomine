using FastEndpoints;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

/// <summary>Tells a client whether to show a single sign-on button, and what the phone needs to sign in directly.</summary>
public sealed record SsoInfoResponse(
    bool Enabled,
    string? DisplayName,
    string? LoginUrl,
    bool AppSsoEnabled,
    string? AppAuthority,
    string? AppClientId,
    string[] AppScopes,
    string? AppRedirectUri);

public sealed class GetSsoInfo(IOptions<SsoOptions> options) : EndpointWithoutRequest<SsoInfoResponse>
{
    public override void Configure()
    {
        Get("accounts/sso");
        AllowAnonymous();
        Description(d => d.Produces<SsoInfoResponse>(200), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var sso = options.Value;
        var web = sso.WebEnabled;
        var app = sso.AppSsoEnabled;
        await Send.OkAsync(
            new SsoInfoResponse(
                web,
                web || app ? sso.DisplayName : null,
                web ? "/api/v1/accounts/sso/login" : null,
                app,
                app ? sso.Authority : null,
                app ? sso.AppClientId : null,
                app ? sso.AppScopes : [],
                app ? sso.AppRedirectUri : null),
            ct);
    }
}
