using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// The email that confirms a sign-up address, in the member's language. Wording in both resx files like the
/// password reset email, and text and HTML from the same words: no tracking, no images.
/// </summary>
public static class EmailVerificationEmail
{
    public static string Subject => EmailStrings.Get("VerifySubject");

    public static EmailContent Confirmation(string link)
    {
        var intro = EmailStrings.Get("VerifyIntro");
        var expiry = EmailStrings.Get("VerifyExpiry");
        var subject = Subject;
        var text = $"{intro}\n\n{link}\n\n{expiry}";
        var html = EmailLayout.Render(
            subject,
            intro,
            EmailLayout.Paragraph(intro)
            + EmailLayout.Button(link, EmailStrings.Get("VerifyAction"))
            + EmailLayout.Muted(link)
            + EmailLayout.Paragraph(expiry));
        return new EmailContent(subject, text, html);
    }
}
