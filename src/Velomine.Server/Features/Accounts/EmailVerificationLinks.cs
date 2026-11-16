using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Demo;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// A confirmed address is required to sign in only when the server can send email. Without SMTP there is no
/// verification message, so a self-hosted club would lock every new member out. A demo never requires it: its
/// shared accounts are not real mailboxes, and the demo's SMTP is only for the feedback form.
/// </summary>
public static class EmailVerification
{
    public static bool Required(IOptions<SmtpOptions> smtp, IOptions<DemoOptions> demo) => smtp.Value.Configured && !demo.Value.Enabled;
}

/// <summary>
/// Builds the link that confirms a member's address. The token is in the URL fragment, so a browser never sends it
/// to the server in an address line or a Referer header. The address comes from configuration, never the incoming
/// Host, so a forged Host cannot point the link at another site.
/// </summary>
public sealed class EmailVerificationLinks(UserManager<User> users, IOptions<PublicUrlOptions> publicUrl, IOptions<SmtpOptions> smtp, IOptions<DemoOptions> demo)
{
    /// <summary>When the token stops working; the same in the email's wording.</summary>
    public static readonly TimeSpan Lifetime = TimeSpan.FromHours(24);

    /// <summary>The link, or null when email is off and there is nothing to send.</summary>
    public async Task<string?> CreateAsync(User user)
    {
        if (!EmailVerification.Required(smtp, demo)) return null;
        var token = await users.GenerateEmailConfirmationTokenAsync(user);
        var baseUrl = publicUrl.Value.PublicUrl.TrimEnd('/');
        return $"{baseUrl}/verify-email#token={Uri.EscapeDataString(token)}&email={Uri.EscapeDataString(user.Email!)}";
    }
}
