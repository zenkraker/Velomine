using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Builds the one-time link a member opens to choose a new password. The token is in the URL fragment, so a browser
/// never sends it to the server in an address line or a Referer header. The link uses the configured public address,
/// never the incoming Host, so a forged Host cannot point it at another site.
/// </summary>
public sealed class PasswordResetLinks(UserManager<User> users, TimeProvider clock, IOptions<PublicUrlOptions> publicUrl)
{
    /// <summary>How long a reset link works. Identity rejects a token older than this.</summary>
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(30);

    public DateTimeOffset ExpiresAt => clock.GetUtcNow().Add(Lifetime);

    public async Task<string> CreateAsync(User user)
    {
        var token = await users.GeneratePasswordResetTokenAsync(user);
        var baseUrl = publicUrl.Value.PublicUrl.TrimEnd('/');
        return $"{baseUrl}/reset-password#token={Uri.EscapeDataString(token)}&email={Uri.EscapeDataString(user.Email!)}";
    }
}
