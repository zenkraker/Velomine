using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>A ready ride as totals and goals see it: the day it counts on and what it adds up to.</summary>
public readonly record struct RideDay(
    DateOnly LocalDate,
    double DistanceM,
    double MovingS,
    double ElevationGainM,
    double Tss = 0,
    double Trimp = 0);

/// <summary>Optional dimension filters for a totals or training range. Null means every ride.</summary>
public readonly record struct RideFilter(
    string? Discipline = null,
    string? Assist = null,
    string? Environment = null,
    bool? Commute = null)
{
    public IQueryable<Ride> Apply(IQueryable<Ride> query)
    {
        var discipline = Discipline;
        var assist = Assist;
        var environment = Environment;
        var commute = Commute;
        if (discipline is not null) query = query.Where(r => r.Discipline == discipline);
        if (assist is not null) query = query.Where(r => r.Assist == assist);
        if (environment is not null) query = query.Where(r => r.Environment == environment);
        if (commute is { } wanted) query = query.Where(r => r.Commute == wanted);
        return query;
    }
}

public static class RideDays
{
    /// <summary>The member's ready rides whose local date falls in [from, to).</summary>
    public static async Task<List<RideDay>> LoadAsync(
        VelomineDbContext db,
        Guid userId,
        MemberClock clock,
        DateOnly from,
        DateOnly to,
        CancellationToken ct,
        int? ftpW = null,
        RideFilter filter = default)
    {
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var query = db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime >= fromUtc && r.StartTime < toUtc);
        var rides = await filter.Apply(query)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes, r.DistanceM, r.MovingS, r.ElevationGainM, r.NormalizedPowerW, r.Tss, r.Trimp })
            .ToListAsync(ct);

        return [.. rides
            .Select(r => new RideDay(
                clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes),
                r.DistanceM ?? 0,
                r.MovingS ?? 0,
                r.ElevationGainM ?? 0,
                // Rides read before the profile had an FTP have no stored TSS; work it out now.
                r.Tss ?? TrainingLoad.PowerLoad(r.NormalizedPowerW, r.MovingS ?? 0, ftpW).Tss ?? 0,
                r.Trimp ?? 0))
            .Where(r => r.LocalDate >= from && r.LocalDate < to)];
    }
}
