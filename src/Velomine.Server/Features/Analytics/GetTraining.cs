using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

public sealed class TrainingRequest
{
    /// <summary>How many days to show, ending today: 7 to 730, default 90.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

/// <summary>One day of training: what was ridden and what it cost. Fitness, fatigue and form are the usual CTL, ATL and TSB.</summary>
public sealed record TrainingDay(
    DateOnly Date,
    int Rides,
    double DistanceM,
    double MovingS,
    double ElevationGainM,
    double Tss,
    double Trimp,
    double Fitness,
    double Fatigue,
    double Form);

public sealed record TrainingResponse(
    int DayCount,
    DateOnly From,
    DateOnly To,
    int Rides,
    double DistanceM,
    double MovingS,
    double ElevationGainM,
    double Tss,
    double Trimp,
    TrainingDay[] Days);

public sealed class TrainingValidator : Validator<TrainingRequest>
{
    public TrainingValidator()
    {
        RuleFor(x => x.Days).InclusiveBetween(7, 730).When(x => x.Days.HasValue);
    }
}

/// <summary>
/// Load and form over a date range: daily TSS and TRIMP, plus fitness (42-day average), fatigue (7-day average) and
/// form (their difference). Worked out from the rides on each request; the 42 days before the range seed the averages.
/// </summary>
public sealed class GetTraining(VelomineDbContext db, TimeProvider time) : Endpoint<TrainingRequest, TrainingResponse>
{
    private const int FitnessDays = 42;
    private const int FatigueDays = 7;

    public override void Configure()
    {
        Get("analytics/training");
        Description(d => d.Produces<TrainingResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(TrainingRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var days = req.Days ?? 90;
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

        await Send.OkAsync(
            new TrainingResponse(
                days,
                from,
                to,
                result.Sum(d => d.Rides),
                result.Sum(d => d.DistanceM),
                result.Sum(d => d.MovingS),
                result.Sum(d => d.ElevationGainM),
                Math.Round(result.Sum(d => d.Tss), 1),
                Math.Round(result.Sum(d => d.Trimp), 1),
                [.. result]),
            ct);
    }

    private readonly record struct DayTotals(
        int Rides,
        double DistanceM,
        double MovingS,
        double ElevationGainM,
        double Tss,
        double Trimp);
}
