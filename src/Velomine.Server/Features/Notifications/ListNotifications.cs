using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Features.Notifications;

public sealed class ListNotificationsRequest
{
    /// <summary>1 to 100, default 50.</summary>
    [QueryParam]
    public int? Limit { get; set; }
}

public sealed record NotificationResponse(
    Guid Id,
    string Type,
    string Subject,
    Guid? RideId,
    Guid? BikeId,
    Guid? ComponentId,
    Guid? AboutUserId,
    Guid? PlannedRideId,
    DateTimeOffset CreatedAt,
    bool IsRead,
    /// <summary>The session a "Was this your …?" notification asks about; null for every other type.</summary>
    TrainingRideMatch? Training = null,
    /// <summary>The session a training notification is about: today's, or one made easy, moved or skipped.</summary>
    TrainingSessionNotice? Notice = null);

/// <summary>Newest first. UnreadCount counts all unread ones, not only those in the list.</summary>
public sealed record ListNotificationsResponse(NotificationResponse[] Notifications, int UnreadCount);

public sealed class ListNotificationsValidator : Validator<ListNotificationsRequest>
{
    public ListNotificationsValidator() => RuleFor(x => x.Limit).InclusiveBetween(1, 100).When(x => x.Limit.HasValue);
}

public sealed class ListNotifications(VelomineDbContext db) : Endpoint<ListNotificationsRequest, ListNotificationsResponse>
{
    public override void Configure()
    {
        Get("notifications");
        Description(d => d.Produces<ListNotificationsResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(ListNotificationsRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var mine = db.Notifications.AsNoTracking().Where(n => n.UserId == userId);
        var rows = await mine
            .OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id)
            .Take(req.Limit ?? 50)
            .Select(n => new { Notification = n, n.TrainingSessionId })
            .ToArrayAsync(ct);
        var list = rows
            .Select(r => new NotificationResponse(r.Notification.Id, r.Notification.Type, r.Notification.Subject,
                r.Notification.RideId, r.Notification.BikeId, r.Notification.ComponentId, r.Notification.AboutUserId,
                r.Notification.PlannedRideId, r.Notification.CreatedAt, r.Notification.ReadAt != null))
            .ToArray();
        // The questions in the list carry the session they ask about, so the inbox asks it in the words of the screen
        // without reading every ride again.
        var asked = list.Where(n => n.Type == NotificationTypes.TrainingSessionQuestion && n.RideId is not null).ToList();
        if (asked.Count > 0)
        {
            var rides = asked.Select(n => n.RideId!.Value).Distinct().ToList();
            var sessions = await db.TrainingSessions.AsNoTracking()
                .Where(s => s.UserId == userId && s.QuestionRideId != null && rides.Contains(s.QuestionRideId.Value))
                .ToListAsync(ct);
            var byRide = sessions.ToDictionary(s => s.QuestionRideId!.Value, TrainingRideMatch.Of);
            list = [.. list.Select(n => n.RideId is { } ride && byRide.TryGetValue(ride, out var match)
                ? n with { Training = match }
                : n)];
        }

        // A training notification carries the session it is about, so the inbox words it in the screen's language and
        // offers the way back to it. The subject stays as it was, so a session the night has rewritten still speaks.
        var sessionIds = rows.Where(r => r.TrainingSessionId != null).Select(r => r.TrainingSessionId!.Value).Distinct().ToList();
        if (sessionIds.Count > 0)
        {
            var bySession = (await db.TrainingSessions.AsNoTracking()
                    .Where(s => s.UserId == userId && sessionIds.Contains(s.Id))
                    .ToListAsync(ct))
                .ToDictionary(s => s.Id, TrainingSessionNotice.Of);
            for (var i = 0; i < rows.Length; i++)
                if (rows[i].TrainingSessionId is { } id && bySession.TryGetValue(id, out var notice))
                    list[i] = list[i] with { Notice = notice };
        }
        var unread = await mine.CountAsync(n => n.ReadAt == null, ct);
        await Send.OkAsync(new ListNotificationsResponse(list, unread), ct);
    }
}
