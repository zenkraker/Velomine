using System.Globalization;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// The languages email is written in. A stored language the server has no translation for falls back to English,
/// so the content and the lang attribute never disagree. A member with no language follows the device, which the
/// server cannot see when it sends, so that case is English too.
/// </summary>
public static class EmailLanguage
{
    public const string Default = "en";

    public static string Resolve(string? language) =>
        language?.StartsWith("it", StringComparison.OrdinalIgnoreCase) == true ? "it" : Default;

    /// <summary>The language the email being written is in.</summary>
    public static string Current => Resolve(CultureInfo.CurrentUICulture.Name);

    /// <summary>
    /// Emails are written by background work with no request culture, so the member's language is applied to the
    /// resource lookup for the duration of one message.
    /// </summary>
    public static CultureScope Use(string? language)
    {
        var previous = CultureInfo.CurrentUICulture;
        CultureInfo.CurrentUICulture = CultureInfo.GetCultureInfo(Resolve(language));
        return new CultureScope(previous);
    }

    public sealed class CultureScope(CultureInfo previous) : IDisposable
    {
        public void Dispose() => CultureInfo.CurrentUICulture = previous;
    }
}
