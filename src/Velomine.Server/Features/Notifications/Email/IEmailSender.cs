namespace Velomine.Server.Features.Notifications.Email;

public sealed record OutgoingEmail(string To, string Subject, string Body);

/// <summary>What happened to one message. The server-level failure is reported separately by the batch.</summary>
public enum EmailOutcome
{
    /// <summary>Not delivered and not known to be refused: try again on the next run.</summary>
    NotSent,
    Sent,
    /// <summary>The server refused this address for good; do not try it again.</summary>
    RecipientRejected,
}

public readonly record struct EmailResult(OutgoingEmail Email, EmailOutcome Outcome);

/// <summary>
/// One SMTP session's outcome. Results line up with the messages sent in, in order. A failure means the session
/// stopped early; the messages after it are left <see cref="EmailOutcome.NotSent"/> for the next run.
/// </summary>
public sealed record EmailBatchResult(IReadOnlyList<EmailResult> Results, Exception? Failure);

/// <summary>Sends plain-text emails through the SMTP server set in the environment.</summary>
public interface IEmailSender
{
    /// <summary>Sends all messages over one connection. A refused recipient does not stop the rest.</summary>
    Task<EmailBatchResult> SendAsync(IReadOnlyList<OutgoingEmail> emails, CancellationToken ct);
}
