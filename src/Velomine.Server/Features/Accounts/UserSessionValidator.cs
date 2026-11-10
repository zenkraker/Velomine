using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Identity's stamp check, plus the session row: a cookie whose session was revoked stops working at the next
/// validation, at most five minutes later. Existing cookies from before sessions existed are rejected the same way.
/// </summary>
public sealed class UserSessionValidator(
    IOptions<SecurityStampValidatorOptions> options,
    SignInManager<User> signInManager,
    ILoggerFactory logger,
    VelomineDbContext db,
    TimeProvider clock)
    : SecurityStampValidator<User>(options, signInManager, logger)
{
    public override async Task ValidateAsync(CookieValidatePrincipalContext context)
    {
        await base.ValidateAsync(context);
        if (context.Principal is null) return;

        var sessionId = context.Principal.SessionId();
        var now = clock.GetUtcNow();
        var alive = sessionId is { } id
            && await db.UserSessions.AsNoTracking()
                .AnyAsync(s => s.Id == id && s.RevokedAt == null && s.ExpiresAt > now, context.HttpContext.RequestAborted);

        if (alive) return;
        context.RejectPrincipal();
        await context.HttpContext.SignOutAsync(IdentityConstants.ApplicationScheme);
    }
}
