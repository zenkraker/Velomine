using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Notifications;

public sealed class NotificationIdRequest
{
    public Guid Id { get; set; }
}

public sealed class MarkNotificationRead(VelomineDbContext db, TimeProvider time) : Endpoint<NotificationIdRequest>
{
    public override void Configure()
    {
        Post("notifications/{id}/read");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(NotificationIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var now = time.GetUtcNow();
        var found = await db.Notifications.Where(n => n.Id == req.Id && n.UserId == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, n => n.ReadAt ?? now), ct);
        if (found == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}

public sealed class MarkAllNotificationsRead(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("notifications/read");
        Description(d => d.Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var now = time.GetUtcNow();
        await db.Notifications.Where(n => n.UserId == userId && n.ReadAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, now), ct);
        await Send.NoContentAsync(ct);
    }
}
