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

    /// <summary>
    /// Links an event that was just added, or moved to another date, to the ride it was: exactly one ready ride of the
    /// member on that local date, not already another event's ride, and the event is the only unlinked one of that
    /// date. Another unlinked event of the day leaves the choice to the rider.
    /// </summary>
    public static async Task ForEventAsync(VelomineDbContext db, MemberClock clock, TrainingEvent e, CancellationToken ct)
    {
        var events = await db.Events.AsNoTracking()
            .Where(o => o.UserId == e.UserId && o.Id != e.Id)
            .Select(o => new { o.Date, o.RideId })
            .ToListAsync(ct);
        if (events.Any(o => o.Date == e.Date && o.RideId is null)) return;
        var taken = events.Where(o => o.RideId is not null).Select(o => o.RideId!.Value).ToHashSet();

        // A local date is at most 14 hours from UTC, so a day either side catches every ride of it; the exact cut is
        // made below, the same way ListRides decides which day a ride counts on.
        var from = new DateTimeOffset(e.Date.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var until = new DateTimeOffset(e.Date.AddDays(2).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rides = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == e.UserId && r.Status == RideStatus.Ready && r.StartTime != null
                && r.StartTime >= from && r.StartTime < until)
            .Select(r => new { r.Id, r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);
        var onDay = rides
            .Where(r => clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes) == e.Date)
            .Select(r => r.Id)
            .ToList();
        if (onDay.Count == 1 && !taken.Contains(onDay[0])) e.RideId = onDay[0];
    }
}
