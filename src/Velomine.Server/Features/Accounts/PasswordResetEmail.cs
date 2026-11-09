using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// The one email a password reset, or an account with no password, sends, in the member's language. Text and
/// HTML come from the same wording: no tracking, no images.
/// </summary>
public static class PasswordResetEmail
{
    public static string Subject => EmailStrings.Get("ResetSubject");

    public static string SsoSubject => EmailStrings.Get("SsoSubject");

    public static EmailContent Reset(string link)
    {
        var intro = EmailStrings.Get("ResetIntro");
        var expiry = EmailStrings.Get("ResetExpiry");
        var subject = Subject;
        var text = $"{intro}\n\n{link}\n\n{expiry}";
        var html = EmailLayout.Render(
            subject,
            intro,
            EmailLayout.Paragraph(intro)
            + EmailLayout.Button(link, EmailStrings.Get("ResetAction"))
            + EmailLayout.Muted(link)
            + EmailLayout.Paragraph(expiry));
        return new EmailContent(subject, text, html);
    }

    public static EmailContent Sso(string provider)
    {
        var subject = SsoSubject;
        var body = EmailStrings.Format("SsoBody", provider);
        return new EmailContent(subject, body, EmailLayout.Render(subject, body, EmailLayout.Paragraph(body)));
    }

    public static EmailContent NoPassword()
    {
        var subject = SsoSubject;
        var body = EmailStrings.Get("NoPasswordBody");
        return new EmailContent(subject, body, EmailLayout.Render(subject, body, EmailLayout.Paragraph(body)));
    }
}
