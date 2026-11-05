using FastEndpoints;
using FluentValidation;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

public sealed class TotalsRequest
{
    /// <summary>week, month or year.</summary>
    [QueryParam]
    public string Period { get; set; } = Periods.Week;

    /// <summary>How many periods, ending with the current one: 1 to 60, default 12.</summary>
    [QueryParam]
    public int? Count { get; set; }
}

/// <summary>One period's totals. End is the period's last day.</summary>
public sealed record PeriodTotals(DateOnly Start, DateOnly End, int Rides, double DistanceM, double MovingS, double ElevationGainM);

/// <summary>Oldest first; the last entry is the current period, so far.</summary>
public sealed record TotalsResponse(string Period, PeriodTotals[] Totals);

public sealed class TotalsValidator : Validator<TotalsRequest>
{
    public TotalsValidator()
    {
        RuleFor(x => x.Period).Must(p => Periods.All.Contains(p)).WithMessage("Choose week, month or year.");
        RuleFor(x => x.Count).InclusiveBetween(1, 60).When(x => x.Count.HasValue);
    }
}

/// <summary>Distance, riding time, climbing and number of rides per week, month or year; worked out from the rides on each request.</summary>
public sealed class GetTotals(VelomineDbContext db, TimeProvider time) : Endpoint<TotalsRequest, TotalsResponse>
{
    public override void Configure()
    {
        Get("analytics/totals");
        Description(d => d.Produces<TotalsResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(TotalsRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);

        var starts = new List<DateOnly> { Periods.StartOf(clock.Today, req.Period, clock.FirstDayOfWeek) };
        for (var i = 1; i < (req.Count ?? 12); i++) starts.Insert(0, Periods.Previous(starts[0], req.Period));
        var end = Periods.Next(starts[^1], req.Period);

        var rides = await RideDays.LoadAsync(db, userId, clock, starts[0], end, ct);
        var totals = starts.Select(start =>
        {
            var next = Periods.Next(start, req.Period);
            var inside = rides.Where(r => r.LocalDate >= start && r.LocalDate < next).ToList();
            return new PeriodTotals(start, next.AddDays(-1), inside.Count, inside.Sum(r => r.DistanceM), inside.Sum(r => r.MovingS), inside.Sum(r => r.ElevationGainM));
        });

        await Send.OkAsync(new TotalsResponse(req.Period, [.. totals]), ct);
    }
}
