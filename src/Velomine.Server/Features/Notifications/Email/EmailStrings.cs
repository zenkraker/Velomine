using System.Globalization;
using System.Resources;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// The wording of every email, in Resources/Features/Notifications/Email. The Italian notification lines mirror
/// the app's app_it.arb keys so the email and the screen say the same thing. A missing key comes back as its
/// name, which a test catches instead of an empty email reaching a member.
/// </summary>
public static class EmailStrings
{
    private static readonly ResourceManager Resources = new(
        "Velomine.Server.Resources.Features.Notifications.Email.EmailStrings", typeof(EmailStrings).Assembly);

    public static string Get(string key) =>
        Resources.GetString(key, CultureInfo.CurrentUICulture) ?? key;

    public static string Format(string key, params object?[] args) =>
        string.Format(CultureInfo.CurrentUICulture, Get(key), args);
}
