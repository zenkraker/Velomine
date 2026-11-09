using System.Net.Sockets;
using MailKit;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using Polly;
using Polly.Registry;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The names and failure rules of the two SMTP retry pipelines registered in AdminSetup.</summary>
public static class EmailPipelines
{
    public const string Connect = "email-connect";
    public const string Send = "email-send";

    /// <summary>
    /// Failures worth trying again: nothing was sent yet, or the server refused the session with a temporary code.
    /// A wrong password is not here: it will still be wrong on the next try.
    /// </summary>
    public static bool IsTransient(Exception? exception) =>
        exception is IOException or SocketException or SmtpProtocolException or ServiceNotConnectedException
        || (exception is SmtpCommandException command && (int)command.StatusCode is >= 400 and < 500);

    /// <summary>
    /// A message may only be retried when the server explicitly refused it with a temporary code. A connection lost
    /// after the message was handed over is ambiguous: it may have been delivered, so the next run decides.
    /// </summary>
    public static bool IsSafeToRetrySend(Exception? exception) =>
        exception is SmtpCommandException command && (int)command.StatusCode is >= 400 and < 500;
}

/// <summary>
/// The only place that uses MailKit. One connection carries the whole batch, and the password comes from the
/// environment and goes nowhere else.
/// </summary>
public sealed class MailKitEmailSender(IOptions<SmtpOptions> options, ResiliencePipelineProvider<string> pipelines)
    : IEmailSender
{
    public async Task<EmailBatchResult> SendAsync(IReadOnlyList<OutgoingEmail> emails, CancellationToken ct)
    {
        var smtp = options.Value;
        if (!smtp.Configured) throw new InvalidOperationException("Email is not set up on this server.");

        // Every message starts as "try again later"; a known outcome replaces it.
        var results = new EmailResult[emails.Count];
        for (var i = 0; i < results.Length; i++) results[i] = new(emails[i], EmailOutcome.NotSent);

        SmtpClient? client = null;
        try
        {
            var connect = pipelines.GetPipeline(EmailPipelines.Connect);
            await connect.ExecuteAsync(async token =>
            {
                // A failed attempt leaves the socket unusable, so each try starts with a fresh client.
                client?.Dispose();
                client = new SmtpClient { Timeout = 30_000 };
                await ConnectAsync(client, smtp, token);
            }, ct);

            var send = pipelines.GetPipeline(EmailPipelines.Send);
            for (var i = 0; i < emails.Count; i++)
            {
                var message = Message(emails[i], smtp);
                try
                {
                    await send.ExecuteAsync(async token => await client!.SendAsync(message, token), ct);
                    results[i] = new(emails[i], EmailOutcome.Sent);
                }
                catch (SmtpCommandException ex) when (ex.ErrorCode == SmtpErrorCode.RecipientNotAccepted)
                {
                    // A refused address will not start working: record it and carry on with the rest.
                    results[i] = new(emails[i], EmailOutcome.RecipientRejected);
                }
                catch (SmtpCommandException ex) when ((int)ex.StatusCode is >= 400 and < 500)
                {
                    // Refused for now; the session is still usable and the next run tries this one again.
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    return new EmailBatchResult(results, ex);
                }
            }

            return new EmailBatchResult(results, null);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return new EmailBatchResult(results, ex);
        }
        finally
        {
            if (client is { IsConnected: true })
            {
                try
                {
                    await client.DisconnectAsync(quit: true, CancellationToken.None);
                }
                catch
                {
                    // Closing: nothing useful to do with a disconnect error.
                }
            }

            client?.Dispose();
        }
    }

    private static async Task ConnectAsync(SmtpClient client, SmtpOptions smtp, CancellationToken ct)
    {
        var security = smtp.Security switch
        {
            "ssl" => SecureSocketOptions.SslOnConnect,
            "none" => SecureSocketOptions.None,
            _ => SecureSocketOptions.StartTls,
        };
        await client.ConnectAsync(smtp.Host!, smtp.Port, security, ct);
        if (!string.IsNullOrEmpty(smtp.User)) await client.AuthenticateAsync(smtp.User, smtp.Password ?? "", ct);
    }

    private static MimeMessage Message(OutgoingEmail email, SmtpOptions smtp)
    {
        var message = new MimeMessage();
        message.From.Add(MailboxAddress.Parse(smtp.From!));
        message.To.Add(MailboxAddress.Parse(email.To));
        message.Subject = email.Subject;
        message.Body = new TextPart("plain") { Text = email.Body };
        return message;
    }
}
