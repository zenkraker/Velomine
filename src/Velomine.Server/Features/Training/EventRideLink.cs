using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>
/// Links a ride that was just read for the first time to an event it was, when the rider has exactly one unlinked
/// event and that ride is their only one that local date. Runs only from <see cref="RideIngestionService"/>, before
/// its save: a re-read and a duplicate never get here.
/// </summary>
public static class EventRideLink
{
    public static async Task AddAsync(VelomineDbContext db, MemberClock clock, Ride ride, CancellationToken ct)
    {
        // The ride's own row is still Processing until the caller saves, so it is never one of the others.
        if (ride.Status != RideStatus.Ready || ride.StartTime is not { } start) return;
        var date = clock.LocalDateOf(start, ride.UtcOffsetMinutes);

        var links = await db.Events.AsNoTracking()
            .Where(e => e.UserId == ride.UserId && e.Date == date && e.RideId == null)
            .Select(e => e.Id)
            .ToListAsync(ct);
        if (links.Count != 1) return;

        // The rides this read is holding are not saved yet, and what the database holds of them is a row still saying
        // Processing: the other rides of that day are the stored ones plus those held beside this one.
        var stored = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == ride.UserId && r.Status == RideStatus.Ready && r.Id != ride.Id)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);
        var read = db.ChangeTracker.Entries<Ride>()
            .Where(e => e.State != EntityState.Deleted && e.Entity.Id != ride.Id
                && e.Entity.UserId == ride.UserId && e.Entity.Status == RideStatus.Ready
                && e.Entity.StartTime is not null)
            .Select(e => (e.Entity.StartTime!.Value, e.Entity.UtcOffsetMinutes));
        if (stored.Any(o => o.StartTime is { } t && clock.LocalDateOf(t, o.UtcOffsetMinutes) == date)
            || read.Any(o => clock.LocalDateOf(o.Item1, o.UtcOffsetMinutes) == date)) return;

        // Written directly: a change to a tracked event made before the caller's save is lost when that save
        // fails and its rows are detached.
        await db.Events.Where(e => e.Id == links[0]).ExecuteUpdateAsync(e => e.SetProperty(x => x.RideId, ride.Id), ct);
    }
}
