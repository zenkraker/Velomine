using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

public sealed class StartSsoRequest
{
    /// <summary>Where to go after signing in. A path on this server; anything else becomes "/".</summary>
    public string? ReturnUrl { get; set; }

    /// <summary>
    /// Sent by the phone app, which signs in through the system browser and is handed back through its own link
    /// instead of a web page: the PKCE S256 challenge (base64url of the SHA-256 of a secret the app keeps).
    /// </summary>
    public string? CodeChallenge { get; set; }
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
        var redirect = "/api/v1/accounts/sso/callback?returnUrl=" + Uri.EscapeDataString(returnUrl);
        if (req.CodeChallenge is not null)
        {
            if (!SsoAppCodes.IsChallenge(req.CodeChallenge))
            {
                AddError(r => r.CodeChallenge!, "Not a PKCE S256 challenge.");
                await Send.ErrorsAsync(400, ct);
                return;
            }

            redirect += "&codeChallenge=" + Uri.EscapeDataString(req.CodeChallenge);
        }

        var properties = new AuthenticationProperties { RedirectUri = redirect };
        await Send.ResultAsync(Results.Challenge(properties, [SsoOptions.Scheme]));
    }
}
