using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

public sealed class EventIdRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>What the rider typed, plus the event's id from the address.</summary>
public sealed class UpdateEventRequest : EventRequest
{
    public Guid Id { get; set; }
}

public sealed class UpdateEventValidator : Validator<UpdateEventRequest>
{
    public UpdateEventValidator()
    {
        Include(new EventRequestValidator());
    }
}

/// <summary>Another rider's event looks exactly like an event that does not exist.</summary>
public sealed class UpdateEvent(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateEventRequest, EventResponse>
{
    public override void Configure()
    {
        Put("training/events/{id}");
        Description(d => d.Accepts<UpdateEventRequest>("application/json").Produces<EventResponse>(200)
            .ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateEventRequest req, CancellationToken ct)
    {
        var e = await db.Events.FirstOrDefaultAsync(e => e.Id == req.Id && e.UserId == User.UserId(), ct);
        if (e is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var moved = e.Date != req.Date;
        AddEvent.Apply(e, req);
        // Only a moved date looks at the ride again: a rename never re-links what the rider unlinked.
        if (moved)
        {
            var clock = await MemberClock.ForAsync(db, e.UserId, time, ct);
            // A link that no longer fits is dropped first, so only a ride of the new day can take it.
            if (e.RideId is { } rideId)
            {
                var ride = await db.Rides.AsNoTracking().Where(r => r.Id == rideId)
                    .Select(r => new { r.StartTime, r.UtcOffsetMinutes }).FirstOrDefaultAsync(ct);
                if (ride?.StartTime is not { } start || clock.LocalDateOf(start, ride.UtcOffsetMinutes) != e.Date)
                    e.RideId = null;
            }
            await EventRideLink.ForEventAsync(db, clock, e, ct);
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(EventResponse.From(e), ct);
    }
}

public sealed class DeleteEvent(VelomineDbContext db) : Endpoint<EventIdRequest>
{
    public override void Configure()
    {
        Delete("training/events/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(EventIdRequest req, CancellationToken ct)
    {
        var deleted = await db.Events
            .Where(e => e.Id == req.Id && e.UserId == User.UserId())
            .ExecuteDeleteAsync(ct);
        if (deleted == 0)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}

/// <summary>The ride that was this event, or null to unlink it. The ride must be the rider's own and on the event's day.</summary>
public sealed class SetEventRideRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public Guid? RideId { get; set; }
}

public sealed class SetEventRide(VelomineDbContext db, TimeProvider time) : Endpoint<SetEventRideRequest, EventResponse>
{
    public override void Configure()
    {
        Put("training/events/{id}/ride");
        Description(d => d.Accepts<SetEventRideRequest>("application/json").Produces<EventResponse>(200)
            .ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetEventRideRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var e = await db.Events.FirstOrDefaultAsync(e => e.Id == req.Id && e.UserId == userId, ct);
        if (e is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (req.RideId is { } rideId)
        {
            var ride = await db.Rides.AsNoTracking()
                .Where(r => r.Id == rideId && r.UserId == userId && r.Status == RideStatus.Ready
                    && r.StartTime != null)
                .Select(r => new { r.StartTime, r.UtcOffsetMinutes })
                .FirstOrDefaultAsync(ct);
            if (ride is null)
            {
                await Send.NotFoundAsync(ct);
                return;
            }

            // A ride counts on the day it was ridden where the rider was, which is the day the event keeps.
            var clock = await MemberClock.ForAsync(db, userId, time, ct);
            if (clock.LocalDateOf(ride.StartTime!.Value, ride.UtcOffsetMinutes) != e.Date)
            {
                await Send.ResultAsync(TypedResults.Problem(
                    "The ride is not on the day of the event.", statusCode: StatusCodes.Status400BadRequest));
                return;
            }
        }

        e.RideId = req.RideId;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(EventResponse.From(e), ct);
    }
}
