using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>One week of aerobic efficiency: the mean efficiency factor of the steady rides in it.</summary>
public sealed record EfficiencyWeek(DateOnly WeekStart, double EfficiencyFactor, int Rides);

/// <summary>
/// Aerobic efficiency over time (Story 7): the mean efficiency factor of the steady rides of each week, because only
/// a steady ride says anything about power for the same heart rate. Worked out on every request from the stored rides.
/// </summary>
public static class Efficiency
{
    public static async Task<EfficiencyWeek[]> LoadAsync(
        VelomineDbContext db,
        Guid userId,
        MemberClock clock,
        DateOnly from,
        DateOnly to,
        CancellationToken ct,
        RideFilter filter = default)
    {
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var query = db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime >= fromUtc && r.StartTime < toUtc
                && r.Steady == true && r.EfficiencyFactor != null);
        var rides = await filter.Apply(query)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes, r.EfficiencyFactor })
            .ToListAsync(ct);

        var weeks = new Dictionary<DateOnly, (double Sum, int Rides)>();
        foreach (var ride in rides)
        {
            var date = clock.LocalDateOf(ride.StartTime!.Value, ride.UtcOffsetMinutes);
            if (date < from || date >= to) continue;

            var week = Periods.StartOf(date, Periods.Week, clock.FirstDayOfWeek);
            var total = weeks.GetValueOrDefault(week);
            weeks[week] = (total.Sum + ride.EfficiencyFactor!.Value, total.Rides + 1);
        }

        return [.. weeks
            .OrderBy(w => w.Key)
            .Select(w => new EfficiencyWeek(w.Key, Math.Round(w.Value.Sum / w.Value.Rides, 2), w.Value.Rides))];
    }
}
