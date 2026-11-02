using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

public sealed class StartSsoRequest
{
    /// <summary>Where to go after signing in. A path on this server; anything else becomes "/".</summary>
    public string? ReturnUrl { get; set; }
}

/// <summary>Sends the browser to the identity provider. The provider sends it back to /signin-oidc, then to the callback.</summary>
public sealed class StartSso(IOptions<SsoOptions> options) : Endpoint<StartSsoRequest>
{
    public override void Configure()
    {
        Get("accounts/sso/login");
        AllowAnonymous();
    }

    public override async Task HandleAsync(StartSsoRequest req, CancellationToken ct)
    {
        if (!options.Value.Enabled)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var returnUrl = SsoReturnUrl.Local(req.ReturnUrl);
        var properties = new AuthenticationProperties
        {
            RedirectUri = "/api/v1/accounts/sso/callback?returnUrl=" + Uri.EscapeDataString(returnUrl),
        };
        await Send.ResultAsync(Results.Challenge(properties, [SsoOptions.Scheme]));
    }
}
