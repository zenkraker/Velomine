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
    double Trimp = 0,
    /// <summary>The effort score the fitness and fatigue charts add up, and where it came from.</summary>
    double Load = 0,
    string? LoadSource = null);

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
        RideFilter filter = default,
        bool includeFeel = true)
    {
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var query = db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime >= fromUtc && r.StartTime < toUtc);
        // The rider's own rating of the ride is wellbeing data, so only the owner and a granted coach read it.
        var rides = await (
                from r in filter.Apply(query)
                join f in db.RideFeels.AsNoTracking() on r.Id equals f.RideId into feels
                from feel in feels.DefaultIfEmpty()
                select new
                {
                    r.StartTime,
                    r.UtcOffsetMinutes,
                    r.DistanceM,
                    r.MovingS,
                    r.ElevationGainM,
                    r.NormalizedPowerW,
                    r.Tss,
                    r.HrTss,
                    r.EstimatedTss,
                    r.Trimp,
                    Rpe = feel == null ? (int?)null : feel.Rpe,
                })
            .ToListAsync(ct);

        return [.. rides
            .Select(r =>
            {
                // Rides read before the profile had an FTP have no stored TSS; work it out now.
                var tss = r.Tss ?? TrainingLoad.PowerLoad(r.NormalizedPowerW, r.MovingS ?? 0, ftpW).Tss;
                var feelScore = includeFeel ? TrainingLoad.FeelScore(r.MovingS, r.Rpe) : null;
                var (load, source) = TrainingLoad.Effort(tss, r.HrTss, feelScore, r.EstimatedTss);
                return new RideDay(
                    clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes),
                    r.DistanceM ?? 0,
                    r.MovingS ?? 0,
                    r.ElevationGainM ?? 0,
                    tss ?? 0,
                    r.Trimp ?? 0,
                    load ?? 0,
                    source);
            })
            .Where(r => r.LocalDate >= from && r.LocalDate < to)];
    }
}
