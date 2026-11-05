using System.Security.Claims;
using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Notifications;

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
    IOptions<AccountsOptions> accounts,
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
            var error = await LinkOrCreate(external.Principal!, subject);
            if (error is not null)
            {
                await Fail(returnUrl, error, ct);
                return;
            }
            result = await signIn.ExternalLoginSignInAsync(SsoOptions.Scheme, subject, isPersistent: false, bypassTwoFactor: true);
        }

        if (result.Succeeded) await Send.RedirectAsync(returnUrl, allowRemoteRedirects: false);
        else await Fail(returnUrl, result.IsLockedOut ? "locked_out" : result.IsNotAllowed ? "not_approved" : "failed", ct);
    }

    private Task Fail(string returnUrl, string error, CancellationToken ct) =>
        Send.RedirectAsync(SsoReturnUrl.WithError(returnUrl, error), allowRemoteRedirects: false);

    /// <summary>Returns an error code, or null when the provider identity is now linked to an account.</summary>
    private async Task<string?> LinkOrCreate(ClaimsPrincipal principal, string subject)
    {
        var email = principal.FindFirstValue("email");
        if (string.IsNullOrWhiteSpace(email)) return "no_email";

        // Providers that do not send the claim are common; only an explicit "false" counts as unverified for a new
        // account, but linking to an existing account needs an explicit "true".
        var verified = principal.FindFirstValue("email_verified");
        var info = new UserLoginInfo(SsoOptions.Scheme, subject, sso.Value.DisplayName);

        if (await users.FindByEmailAsync(email) is { } existing)
        {
            if (!string.Equals(verified, "true", StringComparison.OrdinalIgnoreCase)) return "email_not_verified";
            return (await users.AddLoginAsync(existing, info)).Succeeded ? null : "failed";
        }

        if (!sso.Value.AutoCreateUsers) return "no_account";
        if (string.Equals(verified, "false", StringComparison.OrdinalIgnoreCase)) return "email_not_verified";

        var user = new User
        {
            UserName = email,
            Email = email,
            EmailConfirmed = string.Equals(verified, "true", StringComparison.OrdinalIgnoreCase),
            DisplayName = principal.FindFirstValue("name") ?? email.Split('@')[0],
            IsApproved = !accounts.Value.RequireAdminApproval,
            CreatedAt = clock.GetUtcNow(),
        };
        if (!(await users.CreateAsync(user)).Succeeded) return "failed";
        await users.AddToRoleAsync(user, Accounts.Roles.Member);
        if (!(await users.AddLoginAsync(user, info)).Succeeded) return "failed";
        await Notify.SignUpWaitingAsync(db, users, clock, user);
        return null;
    }
}
