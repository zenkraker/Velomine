using Microsoft.AspNetCore.DataProtection;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// A short-lived signed string that names one member. The signature is Data Protection's, so the token cannot be
/// forged or altered, and it stops working after <see cref="Lifetime"/>.
/// </summary>
public abstract class UserToken(IDataProtectionProvider provider, TimeProvider time)
{
    protected abstract string Purpose { get; }

    public abstract TimeSpan Lifetime { get; }

    private ITimeLimitedDataProtector Protector => provider.CreateProtector(Purpose).ToTimeLimitedDataProtector();

    public string Issue(Guid userId) => Protector.Protect(userId.ToString("N"), time.GetUtcNow().Add(Lifetime));

    /// <summary>The member the token was made for, or null when it is not ours, was changed, or has expired.</summary>
    public Guid? Read(string token)
    {
        try
        {
            return Guid.TryParseExact(Protector.Unprotect(token, out var expires), "N", out var id)
                && expires > time.GetUtcNow()
                ? id
                : null;
        }
        catch (System.Security.Cryptography.CryptographicException)
        {
            return null;
        }
    }
}

/// <summary>Short-lived download links for the data export, so a browser with no sign-in of its own can open one.</summary>
public sealed class ExportTokens(IDataProtectionProvider provider, TimeProvider time)
    : UserToken(provider, time)
{
    protected override string Purpose => "velomine.export";

    public override TimeSpan Lifetime => TimeSpan.FromMinutes(2);
}

/// <summary>
/// The short-lived proof that a password was just checked, handed back by the code step. The code step cannot be
/// attempted with only an email known.
/// </summary>
public sealed class TwoFactorChallenges(IDataProtectionProvider provider, TimeProvider time)
    : UserToken(provider, time)
{
    protected override string Purpose => "velomine.two-factor";

    public override TimeSpan Lifetime => TimeSpan.FromMinutes(5);
}

public sealed record TwoFactorRequiredResponse(bool TwoFactorRequired, string Challenge);
