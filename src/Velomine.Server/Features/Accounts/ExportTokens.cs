using Microsoft.AspNetCore.DataProtection;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Short-lived download links for the data export. The link carries the member's id, protected and expiring (Data
/// Protection), so it can be opened by a browser that has no sign-in of its own: the phone app hands it to the system
/// browser, which then saves the ZIP.
/// </summary>
public sealed class ExportTokens(IDataProtectionProvider provider, TimeProvider time)
{
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(2);

    private const string Purpose = "velomine.export";

    private ITimeLimitedDataProtector Protector => provider.CreateProtector(Purpose).ToTimeLimitedDataProtector();

    public string Issue(Guid userId) => Protector.Protect(userId.ToString("N"), time.GetUtcNow().Add(Lifetime));

    /// <summary>The member the link was made for, or null when it is not one of ours, was changed, or has expired.</summary>
    public Guid? Read(string token)
    {
        try
        {
            return Guid.TryParseExact(Protector.Unprotect(token, out var expires), "N", out var id) && expires > time.GetUtcNow() ? id : null;
        }
        catch (System.Security.Cryptography.CryptographicException)
        {
            return null;
        }
    }
}
