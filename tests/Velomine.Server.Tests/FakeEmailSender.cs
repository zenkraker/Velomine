using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>Stands in for the mail server: keeps what was sent, and can be told to fail.</summary>
public sealed class FakeEmailSender : IEmailSender
{
    public List<OutgoingEmail> Sent { get; } = [];

    public Exception? Fail { get; set; }

    /// <summary>Holds the send until the test releases it, to prove the answer does not wait for SMTP.</summary>
    public TaskCompletionSource<bool>? Gate { get; set; }

    public HashSet<string> Rejected { get; } = [];

    public async Task<EmailBatchResult> SendAsync(IReadOnlyList<OutgoingEmail> emails, CancellationToken ct)
    {
        if (Gate is not null) await Gate.Task.ConfigureAwait(false);
        var results = new List<EmailResult>(emails.Count);
        foreach (var email in emails)
        {
            if (Rejected.Contains(email.To))
            {
                results.Add(new EmailResult(email, EmailOutcome.RecipientRejected));
                continue;
            }

            if (Fail is not null) return new EmailBatchResult(results, Fail);

            Sent.Add(email);
            results.Add(new EmailResult(email, EmailOutcome.Sent));
        }

        return new EmailBatchResult(results, null);
    }
}
