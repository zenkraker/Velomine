using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Demo;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Accounts that are not approved, or whose address is unconfirmed while email is configured, cannot sign in
/// (password or SSO); Identity reports "not allowed".
/// </summary>
public sealed class VelomineSignInManager(
    UserManager<User> userManager,
    IHttpContextAccessor contextAccessor,
    IUserClaimsPrincipalFactory<User> claimsFactory,
    IOptions<IdentityOptions> optionsAccessor,
    ILogger<SignInManager<User>> logger,
    IAuthenticationSchemeProvider schemes,
    IUserConfirmation<User> confirmation,
    IOptions<SmtpOptions> smtp,
    IOptions<DemoOptions> demo,
    IOptions<AccountsOptions> accounts)
    : SignInManager<User>(userManager, contextAccessor, claimsFactory, optionsAccessor, logger, schemes, confirmation)
{
    /// <summary>
    /// Approval is the server's setting; the email must be confirmed only on the cloud service with email configured,
    /// because a self-hosted club sends no verification message. <see cref="IdentityOptions.SignIn.RequireConfirmedEmail"/> stays off so the
    /// rule lives here and the app can tell the two refusals apart.
    /// </summary>
    public override async Task<bool> CanSignInAsync(User user) =>
        user.IsApproved
        && (!EmailVerification.Required(smtp, demo, accounts) || user.EmailConfirmed)
        && await base.CanSignInAsync(user);
}
