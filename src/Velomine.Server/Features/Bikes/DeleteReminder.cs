using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed class ReminderIdRequest
{
    public Guid BikeId { get; set; }

    public Guid Id { get; set; }
}

/// <summary>Deletes a reminder. The log entries it wrote stay, just without the link.</summary>
public sealed class DeleteReminder(VelomineDbContext db) : Endpoint<ReminderIdRequest>
{
    public override void Configure()
    {
        Delete("bikes/{bikeId}/reminders/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ReminderIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var deleted = await db.MaintenanceReminders
            .Where(r => r.Id == req.Id && r.BikeId == req.BikeId && db.Bikes.Any(b => b.Id == r.BikeId && b.UserId == userId))
            .ExecuteDeleteAsync(ct);
        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}
