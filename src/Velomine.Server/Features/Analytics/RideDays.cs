using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>A ready ride as totals and goals see it: the day it counts on and what it adds up to.</summary>
public readonly record struct RideDay(DateOnly LocalDate, double DistanceM, double MovingS, double ElevationGainM);

public static class RideDays
{
    /// <summary>The member's ready rides whose local date falls in [from, to).</summary>
    public static async Task<List<RideDay>> LoadAsync(VelomineDbContext db, Guid userId, MemberClock clock, DateOnly from, DateOnly to, CancellationToken ct)
    {
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rides = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime >= fromUtc && r.StartTime < toUtc)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes, r.DistanceM, r.MovingS, r.ElevationGainM })
            .ToListAsync(ct);

        return [.. rides
            .Select(r => new RideDay(clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes), r.DistanceM ?? 0, r.MovingS ?? 0, r.ElevationGainM ?? 0))
            .Where(r => r.LocalDate >= from && r.LocalDate < to)];
    }
}
