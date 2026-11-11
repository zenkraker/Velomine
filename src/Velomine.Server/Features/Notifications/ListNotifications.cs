using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

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
    bool IsRead);

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
        var unread = await mine.CountAsync(n => n.ReadAt == null, ct);
        await Send.OkAsync(new ListNotificationsResponse(list, unread), ct);
    }
}
