namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The wording of a notification in an email, in the member's language. The app words the same notifications on its own screen.</summary>
public static class NotificationText
{
    public static string Sentence(Notification n) => n.Type switch
    {
        NotificationTypes.RideReady => EmailStrings.Format("RideReady", n.Subject),
        NotificationTypes.RideFailed => EmailStrings.Format("RideFailed", n.Subject),
        NotificationTypes.RideDuplicate => EmailStrings.Format("RideDuplicate", n.Subject),
        NotificationTypes.SignUpWaiting => EmailStrings.Format("SignUpWaiting", n.Subject),
        NotificationTypes.PartSoon => EmailStrings.Format("PartSoon", n.Subject),
        NotificationTypes.PartWorn => EmailStrings.Format("PartWorn", n.Subject),
        NotificationTypes.ClubJoinRequest => EmailStrings.Format("ClubJoinRequest", n.Subject),
        NotificationTypes.ClubJoinApproved => EmailStrings.Format("ClubJoinApproved", n.Subject),
        NotificationTypes.ClubJoinDeclined => EmailStrings.Format("ClubJoinDeclined", n.Subject),
        _ => n.Subject,
    };

    public static string Subject(Notification n) => "Velomine: " + Sentence(n);

    /// <summary>One subject for the whole digest; a single item keeps the wording of a one-notification email.</summary>
    public static string Subject(IReadOnlyList<Notification> notifications) => notifications.Count == 1
        ? Subject(notifications[0])
        : EmailStrings.Format("UpdatesSubject", notifications.Count);

    /// <summary>One line per notification and one footer, in both forms, so a burst never repeats a paragraph.</summary>
    public static EmailContent Write(IReadOnlyList<Notification> notifications)
    {
        var sentences = notifications.Select(Sentence).ToList();
        var subject = Subject(notifications);
        var text = string.Join('\n', sentences)
            + "\n\n" + EmailStrings.Get("Open")
            + "\n\n" + EmailStrings.Get("Footer");
        var html = EmailLayout.Render(
            subject,
            notifications.Count == 1 ? sentences[0] : EmailStrings.Format("UpdatesSubject", notifications.Count),
            string.Concat(sentences.Select(EmailLayout.Paragraph))
            + EmailLayout.Muted(EmailStrings.Get("Open"))
            + EmailLayout.Muted(EmailStrings.Get("Footer")));
        return new EmailContent(subject, text, html);
    }
}
