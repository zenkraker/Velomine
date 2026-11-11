using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed class MarkReminderDoneRequest
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The day it was done, today or earlier. Leave out for today.</summary>
    public DateOnly? DoneOn { get; set; }
}

/// <summary>
/// Records a reminder as done: counting starts again from that day, and the service log gets an entry for it.
/// Deleting that entry later does not undo this.
/// </summary>
public sealed class CompleteReminder(VelomineDbContext db, TimeProvider time) : Endpoint<MarkReminderDoneRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/reminders/{id}/done");
        Description(d => d.Accepts<MarkReminderDoneRequest>("application/json").Produces<BikeDetailResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(MarkReminderDoneRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        var reminder = bike is null ? null : await db.MaintenanceReminders.FirstOrDefaultAsync(r => r.Id == req.Id && r.BikeId == bike.Id, ct);
        if (bike is null || reminder is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var doneOn = req.DoneOn ?? clock.Today;
        if (doneOn > clock.Today)
        {
            ThrowError("The day it was done cannot be in the future.");
            return;
        }

        reminder.LastDoneOn = doneOn;
        reminder.NotifiedStatus = null; // a new cycle: it may warn again
        ServiceLogQueries.Add(db, time, bike.Id, doneOn, reminder.Name, ServiceOrigins.Reminder, reminderId: reminder.Id);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, clock, ct), ct);
    }
}
