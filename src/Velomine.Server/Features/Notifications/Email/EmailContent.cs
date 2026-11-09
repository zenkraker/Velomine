namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// One email in both forms. The text part is never optional: it is what plain clients, screen readers and
/// spam filters read, and it is the fallback when the HTML is stripped.
/// </summary>
public sealed record EmailContent(string Subject, string Text, string Html);
