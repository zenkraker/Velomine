using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

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
        int days,
        CancellationToken ct)
    {
        var to = clock.Today;
        var from = to.AddDays(-(days - 1));
        var warmup = from.AddDays(-FitnessDays);

        var ftpW = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.FtpW)
            .FirstAsync(ct);
        var rides = await RideDays.LoadAsync(db, userId, clock, warmup, to.AddDays(1), ct, ftpW: ftpW);
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
                    g.Sum(r => r.Trimp)));

        double fitness = 0, fatigue = 0;
        var result = new List<TrainingDay>(days);
        for (var date = warmup; date <= to; date = date.AddDays(1))
        {
            var day = byDate.GetValueOrDefault(date);
            fitness += (day.Tss - fitness) * (1 - Math.Exp(-1.0 / FitnessDays));
            fatigue += (day.Tss - fatigue) * (1 - Math.Exp(-1.0 / FatigueDays));
            if (date < from) continue;

            result.Add(new TrainingDay(
                date,
                day.Rides,
                day.DistanceM,
                day.MovingS,
                day.ElevationGainM,
                Math.Round(day.Tss, 1),
                Math.Round(day.Trimp, 1),
                Math.Round(fitness, 1),
                Math.Round(fatigue, 1),
                Math.Round(fitness - fatigue, 1)));
        }

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
            [.. result]);
    }

    private readonly record struct DayTotals(
        int Rides,
        double DistanceM,
        double MovingS,
        double ElevationGainM,
        double Tss,
        double Trimp);
}
