using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Accounts;

/// <summary>The identity a provider proved, normalized from the web callback or a phone ID token.</summary>
public sealed record SsoIdentity(string Subject, string? Email, string? Name, bool? EmailVerified)
{
    public static SsoIdentity FromPrincipal(ClaimsPrincipal principal, string subject) => new(
        subject,
        principal.FindFirstValue("email"),
        principal.FindFirstValue("name"),
        ParseEmailVerified(principal.FindFirstValue("email_verified")));

    public static bool? ParseEmailVerified(string? value) => value?.ToLowerInvariant() switch
    {
        "true" => true,
        "false" => false,
        _ => null,
    };
}

/// <summary>The account rules shared by the web callback and the phone token exchange.</summary>
public static class SsoAccounts
{
    /// <summary>Returns an error code, or null when the provider identity is now linked to an account.</summary>
    public static async Task<string?> LinkOrCreateAsync(
        VelomineDbContext db,
        UserManager<User> users,
        SettingsReader settings,
        TimeProvider clock,
        SsoOptions options,
        SsoIdentity identity,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(identity.Email)) return "no_email";
        var email = identity.Email.Trim();
        var info = new UserLoginInfo(SsoOptions.Scheme, identity.Subject, options.DisplayName);

        // Providers that do not send the claim are common; only an explicit "false" counts as unverified for a new
        // account, but linking to an existing account needs an explicit "true".
        if (await users.FindByEmailAsync(email) is { } existing)
        {
            if (identity.EmailVerified != true) return "email_not_verified";
            return (await users.AddLoginAsync(existing, info)).Succeeded ? null : "failed";
        }

        if (!options.AutoCreateUsers) return "no_account";
        if (identity.EmailVerified == false) return "email_not_verified";

        var user = new User
        {
            UserName = email,
            Email = email,
            EmailConfirmed = identity.EmailVerified == true,
            DisplayName = identity.Name ?? email.Split('@')[0],
            IsApproved = !(await settings.GetAsync(ct)).RequireAdminApproval,
            CreatedAt = clock.GetUtcNow(),
        };
        if (!(await users.CreateAsync(user)).Succeeded) return "failed";
        await users.AddToRoleAsync(user, Accounts.Roles.Member);
        if (!(await users.AddLoginAsync(user, info)).Succeeded) return "failed";
        await Notify.SignUpWaitingAsync(db, users, clock, user);
        return null;
    }
}
