using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Analytics;

/// <summary>Records a ride's best power by duration. <see cref="Kind"/> is "all_time" or "90_days".</summary>
public sealed record PowerRecord(int DurationS, int Watts, string Kind);

/// <summary>
/// The personal power records a ride sets, worked out on read from the stored bests. A record is beaten only by
/// strictly more power on an earlier ride, because a tie is not progress. An all-time record outranks a 90-day one.
/// </summary>
public static class PowerRecords
{
    public const string AllTime = "all_time";
    public const string NinetyDays = "90_days";

    private const int NinetyDaysS = 90 * 24 * 3600;

    /// <summary>The durations that count: every one a power curve shows except 1 s, which is noise, not an effort.</summary>
    public static readonly int[] Durations = [.. PowerBests.Durations.Where(d => d > 1)];

    /// <summary>The ride's records, by duration. Empty when another ride of the member is already as good or better.</summary>
    /// <param name="start">The ride's start; a ride without one has no time to be compared against.</param>
    public static async Task<PowerRecord[]> ForRideAsync(
        VelomineDbContext db, Guid userId, Guid rideId, DateTimeOffset? start, CancellationToken ct)
    {
        if (start is not { } started) return [];
        var windowFrom = started.AddSeconds(-NinetyDaysS);
        var durations = Durations;

        // The rides first and their bests by id, with the start compared here: a DateTimeOffset sent to PostgreSQL as a
        // timestamp differs by its offset from the stored timestamptz, so the ride itself would fall outside its own
        // window (a few milliseconds of rotation on a fast machine is enough).
        var rides = await db.Rides.AsNoTracking()
            .Where(r => r.Id == rideId || r.UserId == userId)
            .Select(r => new { r.Id, r.StartTime, r.Status })
            .ToDictionaryAsync(r => r.Id, ct);
        var ids = rides.Values
            .Where(r => r.Id == rideId || (r.Status == RideStatus.Ready && r.StartTime < started))
            .Select(r => r.Id).ToArray();
        var bests = await db.RidePowerBests.AsNoTracking()
            .Where(b => ids.Contains(b.RideId) && durations.Contains(b.DurationS))
            .ToListAsync(ct);

        // A ride being read in this request holds its bests in the context, before they are saved; a change collector
        // lists deleted ones too, so only live entries count. The one being read wins over the database's copy.
        foreach (var tracked in db.ChangeTracker.Entries<RidePowerBest>()
            .Where(e => e.State != EntityState.Deleted && e.Entity.RideId == rideId).Select(e => e.Entity))
        {
            bests.RemoveAll(b => b.RideId == rideId && b.DurationS == tracked.DurationS);
            bests.Add(tracked);
        }

        var mine = bests.Where(b => b.RideId == rideId).ToList();
        if (mine.Count == 0) return []; // the ride has no power, so nothing to record
        var before = bests
            .Where(b => b.RideId != rideId)
            .Select(b => (b.DurationS, b.Watts, Start: rides[b.RideId].StartTime))
            .ToList();

        return
        [
            .. Durations.Select(duration =>
                {
                    if (mine.FirstOrDefault(b => b.DurationS == duration) is not { } best) return null;
                    // The rider's first ride with power has nothing to beat, so an empty list sets no record.
                    var same = before.Where(r => r.DurationS == duration).ToList();
                    var recent = same.Where(r => r.Start >= windowFrom).ToList();
                    var kind = same.Count > 0 && same.All(r => best.Watts > r.Watts) ? AllTime
                        : recent.Count > 0 && recent.All(r => best.Watts > r.Watts) ? NinetyDays
                        : null;
                    return kind is null ? null : new PowerRecord(duration, best.Watts, kind);
                })
                .OfType<PowerRecord>(),
        ];
    }

    /// <summary>
    /// The notification for a ride that set all-time records, worded for the longest one, or null when none of its
    /// records is all-time. A ride older than 30 days of the member's calendar never announces itself.
    /// </summary>
    public static async Task<string?> SubjectAsync(
        VelomineDbContext db, MemberClock clock, Ride ride, CancellationToken ct)
    {
        if (ride.Status != RideStatus.Ready || !ride.NotifiesMember) return null;
        if (ride.StartTime is not { } start) return null;
        if (clock.LocalDateOf(start, ride.UtcOffsetMinutes) < clock.Today.AddDays(-30)) return null;
        if ((await ForRideAsync(db, ride.UserId, ride.Id, start, ct)).LastOrDefault(r => r.Kind == AllTime) is not { } longest)
            return null;
        return $"{DurationWord(longest.DurationS)}: {longest.Watts} W";
    }

    /// <summary>"5 s", "1 min", "20 min": the same words the app uses for a duration.</summary>
    public static string DurationWord(int seconds) => seconds < 60 ? $"{seconds} s" : $"{seconds / 60} min";
}
