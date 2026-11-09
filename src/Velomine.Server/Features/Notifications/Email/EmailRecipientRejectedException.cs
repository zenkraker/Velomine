namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The SMTP server refused this recipient's address. Sending the same mail again will not help.</summary>
public sealed class EmailRecipientRejectedException(Exception inner)
    : Exception("The SMTP server refused the recipient.", inner);
