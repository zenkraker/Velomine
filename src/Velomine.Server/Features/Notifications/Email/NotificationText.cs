namespace Velomine.Server.Features.Notifications.Email;

/// <summary>The wording of a notification in an email. The app words the same notifications on its own screen.</summary>
public static class NotificationText
{
    public static string Sentence(Notification n) => n.Type switch
    {
        NotificationTypes.RideReady => $"Your ride {n.Subject} is ready.",
        NotificationTypes.RideFailed => $"{n.Subject} could not be read.",
        NotificationTypes.RideDuplicate => $"{n.Subject} was already uploaded, so it is hidden.",
        NotificationTypes.SignUpWaiting => $"{n.Subject} signed up and is waiting for approval.",
        NotificationTypes.PartSoon => $"{n.Subject} is nearly worn.",
        NotificationTypes.PartWorn => $"{n.Subject} is worn out. Time to replace it.",
        _ => n.Subject,
    };

    public static string Subject(Notification n) => "Velomine: " + Sentence(n);

    public static string Body(Notification n) =>
        Sentence(n) + "\n\nOpen Velomine to see more.\n\nYou get this email because email notifications are on in your Velomine profile. You can turn them off there.\n";
}
