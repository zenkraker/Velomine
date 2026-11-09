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
                req.Days ?? 90,
                ct,
                new RideFilter(req.Discipline, req.Assist, req.Environment, req.Commute)),
            ct);
    }
}
