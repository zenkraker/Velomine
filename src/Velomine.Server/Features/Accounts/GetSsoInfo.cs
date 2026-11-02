using FastEndpoints;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

/// <summary>Tells a client whether to show a single sign-on button, and where it leads.</summary>
public sealed record SsoInfoResponse(bool Enabled, string? DisplayName, string? LoginUrl);

public sealed class GetSsoInfo(IOptions<SsoOptions> options) : EndpointWithoutRequest<SsoInfoResponse>
{
    public override void Configure()
    {
        Get("accounts/sso");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var sso = options.Value;
        await Send.OkAsync(
            sso.Enabled ? new SsoInfoResponse(true, sso.DisplayName, "/api/v1/accounts/sso/login") : new SsoInfoResponse(false, null, null),
            ct);
    }
}
