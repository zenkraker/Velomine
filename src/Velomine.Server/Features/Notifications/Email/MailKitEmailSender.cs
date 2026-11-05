using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The only place that uses MailKit. The password comes from the environment and goes nowhere else.</summary>
public sealed class MailKitEmailSender(IOptions<SmtpOptions> options) : IEmailSender
{
    public async Task SendAsync(string to, string subject, string body, CancellationToken ct)
    {
        var smtp = options.Value;
        if (!smtp.Configured) throw new InvalidOperationException("Email is not set up on this server.");

        var message = new MimeMessage();
        message.From.Add(MailboxAddress.Parse(smtp.From!));
        message.To.Add(MailboxAddress.Parse(to));
        message.Subject = subject;
        message.Body = new TextPart("plain") { Text = body };

        using var client = new SmtpClient { Timeout = 30_000 };
        var security = smtp.Security switch
        {
            "ssl" => SecureSocketOptions.SslOnConnect,
            "none" => SecureSocketOptions.None,
            _ => SecureSocketOptions.StartTls,
        };
        await client.ConnectAsync(smtp.Host!, smtp.Port, security, ct);
        if (!string.IsNullOrEmpty(smtp.User)) await client.AuthenticateAsync(smtp.User, smtp.Password ?? "", ct);
        await client.SendAsync(message, ct);
        await client.DisconnectAsync(quit: true, ct);
    }
}
