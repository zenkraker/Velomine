namespace Velomine.Server.Features.Notifications.Email;

/// <summary>Sends one plain-text email through the SMTP server set in the environment. Throws when it could not.</summary>
public interface IEmailSender
{
    Task SendAsync(string to, string subject, string body, CancellationToken ct);
}
