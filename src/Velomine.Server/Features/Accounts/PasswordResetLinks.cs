using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Builds the one-time link a member opens to choose a new password. The token is in the URL fragment, so a browser
/// never sends it to the server in an address line or a Referer header.
/// </summary>
public sealed class PasswordResetLinks(UserManager<User> users, TimeProvider clock)
{
    /// <summary>How long a reset link works. Identity rejects a token older than this.</summary>
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(30);

    public DateTimeOffset ExpiresAt => clock.GetUtcNow().Add(Lifetime);

    public async Task<string> CreateAsync(User user, HttpRequest request)
    {
        var token = await users.GeneratePasswordResetTokenAsync(user);
        var baseUrl = $"{request.Scheme}://{request.Host}{request.PathBase}";
        return $"{baseUrl}/reset-password#token={Uri.EscapeDataString(token)}&email={Uri.EscapeDataString(user.Email!)}";
    }
}
