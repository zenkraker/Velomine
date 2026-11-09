using System.Text.Encodings.Web;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// The one HTML shell for every email. Tables and inline styles because Outlook still renders with the Word
/// engine, a preheader for the inbox preview, and dark-mode colours for the clients that ask for them. Every
/// dynamic value is encoded here: member names end up in these messages.
/// </summary>
public static class EmailLayout
{
    private static readonly HtmlEncoder Encoder = HtmlEncoder.Default;

    public static string Render(string title, string preheader, string contentHtml, string? footerHtml = null) => $$"""
        <!doctype html>
        <html lang="{{EmailLanguage.Current}}">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <meta name="supported-color-schemes" content="light dark">
        <title>{{Encoder.Encode(title)}}</title>
        <style>
          @media (prefers-color-scheme: dark) {
            .email-page { background: #18181b !important; }
            .email-card { background: #27272a !important; }
            .email-text { color: #e4e4e7 !important; }
            .email-muted { color: #a1a1aa !important; }
            .email-button { background: #fafafa !important; color: #18181b !important; }
          }
        </style>
        </head>
        <body class="email-page" style="margin: 0; padding: 0; background: #f4f4f5;">
        <div style="display: none; max-height: 0; overflow: hidden; opacity: 0;">{{Encoder.Encode(preheader)}}</div>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" class="email-page" style="background: #f4f4f5;">
        <tr>
        <td align="center" style="padding: 24px 12px;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" class="email-card" style="width: 100%; max-width: 600px; background: #ffffff; border-radius: 8px;">
        <tr>
        <td class="email-text" style="padding: 32px 28px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #18181b;">
        {{contentHtml}}
        {{footerHtml}}
        </td>
        </tr>
        </table>
        </td>
        </tr>
        </table>
        </body>
        </html>
        """;

    public static string Paragraph(string text) =>
        $"<p style=\"margin: 0 0 16px; font-size: 16px; line-height: 1.6;\">{Encoder.Encode(text)}</p>";

    public static string Muted(string text) =>
        $"<p class=\"email-muted\" style=\"margin: 16px 0 0; font-size: 13px; line-height: 1.5; color: #71717a;\">{Encoder.Encode(text)}</p>";

    public static string Button(string href, string label) =>
        $"<p style=\"margin: 0 0 16px;\"><a class=\"email-button\" href=\"{Encoder.Encode(href)}\" style=\"display: inline-block; padding: 12px 20px; border-radius: 6px; background: #18181b; color: #ffffff; text-decoration: none; font-weight: 600;\">{Encoder.Encode(label)}</a></p>";
}
