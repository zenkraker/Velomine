using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using RideEnvironments = Velomine.Server.Features.Rides.Environments;

namespace Velomine.Server.Features.Analytics;

public sealed class TrainingRequest
{
    /// <summary>How many days to show, ending today: 7 to 730, default 90.</summary>
    [QueryParam]
    public int? Days { get; set; }

    /// <summary>road, gravel, mountain or track.</summary>
    [QueryParam]
    public string? Discipline { get; set; }

    /// <summary>none or ebike.</summary>
    [QueryParam]
    public string? Assist { get; set; }

    /// <summary>outdoor, indoor or virtual.</summary>
    [QueryParam]
    public string? Environment { get; set; }

    /// <summary>True or false for a commute, omitted for every ride.</summary>
    [QueryParam]
    public bool? Commute { get; set; }
}

/// <summary>One day of training: what was ridden and what it cost. Fitness and fatigue are the usual CTL and ATL; form
/// is their difference, not TrainingPeaks' TSB.</summary>
public sealed record TrainingDay(
    DateOnly Date,
    int Rides,
    double DistanceM,
    double MovingS,
    double ElevationGainM,
    double Tss,
    double Trimp,
    /// <summary>The rides' effort scores: TSS, else Velomine's hrTSS, else the feel score. Fitness and fatigue follow it.</summary>
    double Load,
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
    TrainingDay[] Days,
    /// <summary>Seiler's three zones over the range, null when no ride had power or heart rate to place.</summary>
    IntensityResponse? Intensity,
    IntensityWeek[] IntensityWeeks,
    /// <summary>The mean efficiency factor of each week's steady rides; a week without one is left out.</summary>
    EfficiencyWeek[] Efficiency,
    /// <summary>How many rides in the range were scored from heart rate, for the note under the fitness chart.</summary>
    int HeartRateLoadRides = 0,
    /// <summary>The last seven days' monotony and strain (Foster 1998); null under a ride filter.</summary>
    double? Monotony = null,
    double? Strain = null,
    /// <summary>What a usual week costs, from the eight blocks before the window; null under four with load.</summary>
    double? StrainUsual = null,
    /// <summary>Every day about as hard this week.</summary>
    bool Monotonous = false,
    /// <summary>Much heavier than the usual week.</summary>
    bool HeavyWeek = false,
    DateOnly? MonotonyFrom = null,
    DateOnly? MonotonyTo = null);

public sealed class TrainingValidator : Validator<TrainingRequest>
{
    public TrainingValidator()
    {
        RuleFor(x => x.Days).InclusiveBetween(7, 730).When(x => x.Days.HasValue);
        RuleFor(x => x.Discipline).Must(v => v is null || Disciplines.All.Contains(v))
            .WithMessage("Choose road, gravel, mountain or track.");
        RuleFor(x => x.Assist).Must(v => v is null || Assists.All.Contains(v))
            .WithMessage("Choose none or ebike.");
        RuleFor(x => x.Environment).Must(v => v is null || RideEnvironments.All.Contains(v))
            .WithMessage("Choose outdoor, indoor or virtual.");
    }
}

/// <summary>
/// Load and form over a date range: daily TSS and TRIMP, plus fitness (42-day average), fatigue (7-day average) and
/// form (their difference). Worked out from the rides on each request; the 42 days before the range seed the averages.
/// </summary>
public sealed class GetTraining(VelomineDbContext db, TimeProvider time) : Endpoint<TrainingRequest, TrainingResponse>
{
    public override void Configure()
    {
        Get("analytics/training");
        Description(d => d.Produces<TrainingResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(TrainingRequest req, CancellationToken ct)
    {
        var clock = await MemberClock.ForAsync(db, User.UserId(), time, ct);
        await Send.OkAsync(
            await TrainingRange.LoadAsync(
                db,
                User.UserId(),
                clock,
                time,
                req.Days ?? 90,
                ct,
                new RideFilter(req.Discipline, req.Assist, req.Environment, req.Commute)),
            ct);
    }
}
