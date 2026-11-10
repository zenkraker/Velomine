using Microsoft.AspNetCore.DataProtection;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// The short-lived proof that a password was just checked, handed back by the code step. The code step cannot be
/// attempted with only an email known.
/// </summary>
public sealed class TwoFactorChallenges(IDataProtectionProvider provider, TimeProvider time)
{
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);

    private const string Purpose = "velomine.two-factor";

    private ITimeLimitedDataProtector Protector => provider.CreateProtector(Purpose).ToTimeLimitedDataProtector();

    public string Issue(Guid userId) => Protector.Protect(userId.ToString("N"), time.GetUtcNow().Add(Lifetime));

    /// <summary>The member the challenge was made for, or null when it is not ours, was changed, or has expired.</summary>
    public Guid? Read(string challenge)
    {
        try
        {
            return Guid.TryParseExact(Protector.Unprotect(challenge, out var expires), "N", out var id) && expires > time.GetUtcNow()
                ? id
                : null;
        }
        catch (System.Security.Cryptography.CryptographicException)
        {
            return null;
        }
    }
}

public sealed record TwoFactorRequiredResponse(bool TwoFactorRequired, string Challenge);
