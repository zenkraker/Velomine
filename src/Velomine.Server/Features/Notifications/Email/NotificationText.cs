namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The wording of a notification in an email. The app words the same notifications on its own screen.</summary>
public static class NotificationText
{
    private const string Footer =
        "\n\nOpen Velomine to see more.\n\nYou get this email because email notifications are on in your Velomine profile. You can turn them off there.\n";

    public static string Sentence(Notification n) => n.Type switch
    {
        NotificationTypes.RideReady => $"Your ride {n.Subject} is ready.",
        NotificationTypes.RideFailed => $"{n.Subject} could not be read.",
        NotificationTypes.RideDuplicate => $"{n.Subject} was already uploaded, so it is hidden.",
        NotificationTypes.SignUpWaiting => $"{n.Subject} signed up and is waiting for approval.",
        NotificationTypes.PartSoon => $"{n.Subject} is nearly worn.",
        NotificationTypes.PartWorn => $"{n.Subject} is worn out. Time to replace it.",
        NotificationTypes.ClubJoinRequest => $"{n.Subject} asked to join your club.",
        NotificationTypes.ClubJoinApproved => $"{n.Subject} accepted you. Welcome!",
        NotificationTypes.ClubJoinDeclined => $"{n.Subject} declined your request to join.",
        _ => n.Subject,
    };

    public static string Subject(Notification n) => "Velomine: " + Sentence(n);

    public static string Body(Notification n) => Sentence(n) + Footer;

    /// <summary>One subject for the whole digest; a single item keeps the wording of a one-notification email.</summary>
    public static string Subject(IReadOnlyList<Notification> notifications) => notifications.Count == 1
        ? Subject(notifications[0])
        : $"Velomine: {notifications.Count} updates";

    /// <summary>One line per notification and the footer once, so a burst never repeats the same paragraph.</summary>
    public static string Body(IReadOnlyList<Notification> notifications) =>
        string.Join('\n', notifications.Select(Sentence)) + Footer;
}
