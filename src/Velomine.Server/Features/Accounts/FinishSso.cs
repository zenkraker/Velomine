using System.Security.Claims;
using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Accounts;

public sealed class FinishSsoRequest
{
    public string? ReturnUrl { get; set; }
}

/// <summary>
/// Turns a completed provider sign-in into a Velomine session. Finds the linked account, or links an existing account
/// with the same verified email, or creates one. Always ends with a redirect: to the return URL, with sso_error=... on failure.
/// </summary>
public sealed class FinishSso(
    SignInManager<User> signIn,
    UserManager<User> users,
    VelomineDbContext db,
    IOptions<SsoOptions> sso,
    SettingsReader settings,
    TimeProvider clock) : Endpoint<FinishSsoRequest>
{
    public override void Configure()
    {
        Get("accounts/sso/callback");
        AllowAnonymous();
    }

    public override async Task HandleAsync(FinishSsoRequest req, CancellationToken ct)
    {
        var returnUrl = SsoReturnUrl.Local(req.ReturnUrl);
        var external = await HttpContext.AuthenticateAsync(IdentityConstants.ExternalScheme);
        await HttpContext.SignOutAsync(IdentityConstants.ExternalScheme); // the provider sign-in is used once
        var subject = external.Principal?.FindFirstValue("sub");
        if (!external.Succeeded || string.IsNullOrEmpty(subject))
        {
            await Fail(returnUrl, "failed", ct);
            return;
        }

        var result = await signIn.ExternalLoginSignInAsync(SsoOptions.Scheme, subject, isPersistent: false, bypassTwoFactor: true);
        if (!result.Succeeded && !result.IsLockedOut && !result.IsNotAllowed)
        {
            var identity = SsoIdentity.FromPrincipal(external.Principal!, subject);
            var error = await SsoAccounts.LinkOrCreateAsync(db, users, settings, clock, sso.Value, identity, ct);
            if (error is not null)
            {
                await Fail(returnUrl, error, ct);
                return;
            }
            result = await signIn.ExternalLoginSignInAsync(SsoOptions.Scheme, subject, isPersistent: false, bypassTwoFactor: true);
        }

        if (!result.Succeeded)
            await Fail(returnUrl, result.IsLockedOut ? "locked_out" : result.IsNotAllowed ? "not_approved" : "failed", ct);
        else
            await Send.RedirectAsync(returnUrl, allowRemoteRedirects: false);
    }

    private Task Fail(string returnUrl, string error, CancellationToken ct) =>
        Send.RedirectAsync(SsoReturnUrl.WithError(returnUrl, error), allowRemoteRedirects: false);
}
