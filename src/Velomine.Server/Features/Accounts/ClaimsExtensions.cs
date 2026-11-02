using System.Security.Claims;

namespace Velomine.Server.Features.Accounts;

public static class ClaimsExtensions
{
    /// <summary>The signed-in member's id. Only call this on endpoints that require sign-in.</summary>
    public static Guid UserId(this ClaimsPrincipal user) => Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
