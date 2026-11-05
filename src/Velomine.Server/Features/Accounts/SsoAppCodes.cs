using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Caching.Memory;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// The one-time codes that carry a finished single sign-on from the system browser back to the phone app.
/// A code is bound to the PKCE challenge the app sent when it started, so another app that catches the redirect
/// (several apps can claim one scheme) cannot use it without the app's secret verifier (RFC 8252 section 8.1).
/// Kept in memory for two minutes: there is one server, and a lost code only means signing in again.
/// </summary>
public sealed class SsoAppCodes(IMemoryCache cache)
{
    private static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(2);

    private sealed record Pending(Guid UserId, string Challenge);

    /// <summary>A PKCE S256 challenge is the base64url of a SHA-256 hash: 43 characters, no padding.</summary>
    public static bool IsChallenge(string? value) =>
        value is { Length: 43 } && value.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_');

    public string Issue(Guid userId, string challenge)
    {
        var code = WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(32));
        cache.Set(Key(code), new Pending(userId, challenge), Lifetime);
        return code;
    }

    /// <summary>
    /// The member the code was issued to, when the verifier matches. The code is used up either way, so a wrong
    /// guess cannot be retried.
    /// </summary>
    public Guid? Redeem(string code, string verifier)
    {
        if (!cache.TryGetValue(Key(code), out Pending? pending) || pending is null) return null;
        cache.Remove(Key(code));

        var hash = WebEncoders.Base64UrlEncode(SHA256.HashData(Encoding.ASCII.GetBytes(verifier)));
        return CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(hash), Encoding.ASCII.GetBytes(pending.Challenge))
            ? pending.UserId
            : null;
    }

    private static string Key(string code) => "sso-app-code:" + code;
}
