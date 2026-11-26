using System.Text.Encodings.Web;
using T = Velomine.Server.Features.Notifications.Email.EmailTokens;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// The one HTML shell for every email. Tables and inline styles because Outlook still renders with the Word
/// engine, a preheader for the inbox preview, and dark-mode colours for the clients that ask for them. Every
/// dynamic value is encoded here: member names end up in these messages. Colours, fonts, radii and spacing come from
/// <see cref="EmailTokens"/>, which mirrors docs/design/tokens.json; the text is never below 16px.
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
            .email-page { background: {{T.CanvasNight}} !important; }
            .email-card { background: {{T.CardNight}} !important; }
            .email-title, .email-text { color: {{T.InkNight}} !important; }
            .email-muted { color: {{T.InkMutedNight}} !important; }
          }
        </style>
        </head>
        <body class="email-page" style="margin: 0; padding: 0; background: {{T.CanvasDay}}; font-family: {{T.Sans}};">
        <div style="display: none; max-height: 0; overflow: hidden; opacity: 0;">{{Encoder.Encode(preheader)}}</div>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" class="email-page" style="background: {{T.CanvasDay}};">
        <tr>
        <td align="center" style="padding: {{T.SpaceXl}} 12px;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" class="email-card" style="width: 100%; max-width: 600px; background: {{T.CardDay}}; border-radius: {{T.RadiusLarge}};">
        <tr>
        <td style="padding: {{T.SpaceXxl}} {{T.SpaceXxl}} 0;">
        <p class="email-title" style="margin: 0; font-family: {{T.Display}}; font-size: 26px; line-height: 28px; font-weight: 400; color: {{T.InkDay}};">Velomine</p>
        </td>
        </tr>
        <tr>
        <td class="email-text" style="padding: {{T.SpaceXl}} {{T.SpaceXxl}} {{T.SpaceXxl}}; font-family: {{T.Sans}}; font-size: 16px; line-height: 24px; color: {{T.InkDay}};">
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

    public static string Heading(string text) =>
        $"<h1 class=\"email-title\" style=\"margin: 0 0 16px; font-family: {T.Display}; font-size: 32px; line-height: 38px; font-weight: 400; color: {T.InkDay};\">{Encoder.Encode(text)}</h1>";

    public static string Paragraph(string text) =>
        $"<p style=\"margin: 0 0 16px; font-size: 16px; line-height: 24px;\">{Encoder.Encode(text)}</p>";

    /// <summary>Secondary text, and the raw link printed under the button. Still 16px: nothing in a message is smaller.</summary>
    public static string Muted(string text) =>
        $"<p class=\"email-muted\" style=\"margin: 16px 0 0; font-size: 16px; line-height: 24px; color: {T.InkMutedDay}; word-break: break-all;\">{Encoder.Encode(text)}</p>";

    /// <summary>The one call to action: a volt pill with on-accent text, the brand's primary button.</summary>
    public static string Button(string href, string label) =>
        $"<p style=\"margin: 8px 0 0;\"><a class=\"email-button\" href=\"{Encoder.Encode(href)}\" style=\"display: inline-block; padding: 14px 28px; border-radius: {T.RadiusPill}; background: {T.Accent}; color: {T.OnAccent}; font-family: {T.Sans}; font-size: 16px; line-height: 20px; font-weight: 700; text-decoration: none;\">{Encoder.Encode(label)}</a></p>";
}
