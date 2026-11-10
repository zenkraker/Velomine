using System.Security.Claims;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// The session id and refresh-token generation travel inside the cookie and the bearer tokens, so a request can say
/// which sign-in it belongs to without a lookup on every call.
/// </summary>
public static class SessionClaims
{
    public const string Id = "vlm_session";
    public const string Generation = "vlm_session_gen";

    public static Guid? SessionId(this ClaimsPrincipal user) =>
        Guid.TryParse(user.FindFirstValue(Id), out var id) ? id : null;

    public static int? SessionGeneration(this ClaimsPrincipal user) =>
        int.TryParse(user.FindFirstValue(Generation), out var generation) ? generation : null;

    public static Claim[] For(Guid sessionId, int generation) =>
        [new Claim(Id, sessionId.ToString("N")), new Claim(Generation, generation.ToString())];
}
