using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

/// <summary>Accounts that are not approved yet cannot sign in (password or SSO); Identity reports "not allowed".</summary>
public sealed class VelomineSignInManager(
    UserManager<User> userManager,
    IHttpContextAccessor contextAccessor,
    IUserClaimsPrincipalFactory<User> claimsFactory,
    IOptions<IdentityOptions> optionsAccessor,
    ILogger<SignInManager<User>> logger,
    IAuthenticationSchemeProvider schemes,
    IUserConfirmation<User> confirmation)
    : SignInManager<User>(userManager, contextAccessor, claimsFactory, optionsAccessor, logger, schemes, confirmation)
{
    public override async Task<bool> CanSignInAsync(User user) =>
        user.IsApproved && await base.CanSignInAsync(user);
}
