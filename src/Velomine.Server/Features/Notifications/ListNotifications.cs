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
    TrainingRideMatch? Training = null);

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
        var list = await mine
            .OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id)
            .Take(req.Limit ?? 50)
            .Select(n => new NotificationResponse(n.Id, n.Type, n.Subject, n.RideId, n.BikeId, n.ComponentId, n.AboutUserId, n.PlannedRideId, n.CreatedAt, n.ReadAt != null))
            .ToArrayAsync(ct);
        // The questions in the list carry the session they ask about, so the inbox asks it in the words of the screen
        // without reading every ride again.
        var asked = list.Where(n => n.Type == NotificationTypes.TrainingSessionQuestion && n.RideId is not null)
            .Select(n => n.RideId!.Value)
            .Distinct()
            .ToList();
        if (asked.Count > 0)
        {
            var sessions = await db.TrainingSessions.AsNoTracking()
                .Where(s => s.UserId == userId && s.QuestionRideId != null && asked.Contains(s.QuestionRideId.Value))
                .ToListAsync(ct);
            var byRide = sessions.ToDictionary(s => s.QuestionRideId!.Value, TrainingRideMatch.Of);
            list = [.. list.Select(n => n.RideId is { } ride && byRide.TryGetValue(ride, out var match)
                ? n with { Training = match }
                : n)];
        }
        var unread = await mine.CountAsync(n => n.ReadAt == null, ct);
        await Send.OkAsync(new ListNotificationsResponse(list, unread), ct);
    }
}
