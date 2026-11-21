using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>The training range shared by the member's own dashboard and a coach's view of an athlete.</summary>
public static class TrainingRange
{
    private const int FitnessDays = 42;
    private const int FatigueDays = 7;

    public static async Task<TrainingResponse> LoadAsync(
        VelomineDbContext db,
        Guid userId,
        MemberClock clock,
        TimeProvider time,
        int days,
        CancellationToken ct,
        RideFilter filter = default,
        bool includeFeel = true)
    {
        var to = clock.Today;
        var from = to.AddDays(-(days - 1));
        var warmup = from.AddDays(-FitnessDays);
        // The strain window is a week plus the eight seven-day blocks before it, so the loads reach 63 days back.
        var strainDays = TrainingStrain.WindowDays + TrainingStrain.PreviousBlocks * 7;
        var loadFrom = warmup < to.AddDays(-strainDays) ? warmup : to.AddDays(-strainDays);

        var ftpW = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.FtpW)
            .FirstAsync(ct);
        var rides = await RideDays.LoadAsync(db, userId, clock, loadFrom, to.AddDays(1), ct, ftpW: ftpW, filter: filter, includeFeel: includeFeel);
        // Fitness, fatigue and form follow each ride's effort score: power, else heart rate, else how hard it felt.
        var byDate = rides
            .GroupBy(r => r.LocalDate)
            .ToDictionary(
                g => g.Key,
                g => new DayTotals(
                    g.Count(),
                    g.Sum(r => r.DistanceM),
                    g.Sum(r => r.MovingS),
                    g.Sum(r => r.ElevationGainM),
                    g.Sum(r => r.Tss),
                    g.Sum(r => r.Trimp),
                    g.Sum(r => r.Load)));

        double fitness = 0, fatigue = 0;
        var result = new List<TrainingDay>(days);
        for (var date = warmup; date <= to; date = date.AddDays(1))
        {
            var day = byDate.GetValueOrDefault(date);
            fitness += (day.Load - fitness) * (1 - Math.Exp(-1.0 / FitnessDays));
            fatigue += (day.Load - fatigue) * (1 - Math.Exp(-1.0 / FatigueDays));
            if (date < from) continue;

            result.Add(new TrainingDay(
                date,
                day.Rides,
                day.DistanceM,
                day.MovingS,
                day.ElevationGainM,
                Math.Round(day.Tss, 1),
                Math.Round(day.Trimp, 1),
                Math.Round(day.Load, 1),
                Math.Round(fitness, 1),
                Math.Round(fatigue, 1),
                Math.Round(fitness - fatigue, 1)));
        }

        // A rider who has not ridden today yet is judged on the week that ended yesterday, so a rest morning is quiet.
        var strain = filter == default
            ? TrainingStrain.Compute(
                rides.Any(r => r.LocalDate == to) ? to : to.AddDays(-1),
                rides.GroupBy(r => r.LocalDate).ToDictionary(g => g.Key, g => g.Sum(r => r.Load)))
            : null;

        var (intensity, weeks) = await Intensity.LoadAsync(db, userId, clock, time, from, to, ct, filter);
        var efficiency = await Efficiency.LoadAsync(db, userId, clock, from, to, ct, filter);

        return new TrainingResponse(
            days,
            from,
            to,
            result.Sum(d => d.Rides),
            result.Sum(d => d.DistanceM),
            result.Sum(d => d.MovingS),
            result.Sum(d => d.ElevationGainM),
            Math.Round(result.Sum(d => d.Tss), 1),
            Math.Round(result.Sum(d => d.Trimp), 1),
            [.. result],
            intensity,
            weeks,
            efficiency,
            // What the progress page says when some rides in the range were scored from heart rate.
            rides.Count(r => r.LocalDate >= from && r.LoadSource == EffortSources.HeartRate),
            strain?.Monotony,
            strain?.Strain,
            strain?.Usual,
            strain?.Monotonous ?? false,
            strain?.HeavyWeek ?? false,
            strain?.From,
            strain?.To);
    }

    private readonly record struct DayTotals(
        int Rides,
        double DistanceM,
        double MovingS,
        double ElevationGainM,
        double Tss,
        double Trimp,
        double Load);
}
