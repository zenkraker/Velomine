using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Analytics;

/// <summary>Best average power for one window length, in watts.</summary>
public sealed record PowerCurvePoint(int Seconds, int Watts);

/// <summary>FTP suggested from a best effort. <see cref="Method"/> is "20min" or "8min".</summary>
public sealed record FtpEstimate(int Watts, string Method, DateOnly From, double? WPerKg);

/// <summary>VO2max estimated from a five-minute effort and the member's weight.</summary>
public sealed record Vo2MaxEstimate(double Value, string Method, DateOnly From);

public sealed record PowerCurveResponse(
    int DayCount,
    DateOnly From,
    DateOnly To,
    int Rides,
    bool HasPower,
    int? CurrentFtpW,
    double? WeightKg,
    PowerCurvePoint[] Points,
    FtpEstimate? Ftp,
    Vo2MaxEstimate? Vo2Max);

public sealed class PowerCurveRequest
{
    /// <summary>How many days to cover, ending today: 7 to 730, default 90.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

public sealed class PowerCurveValidator : Validator<PowerCurveRequest>
{
    public PowerCurveValidator() => RuleFor(x => x.Days).InclusiveBetween(7, 730).When(x => x.Days.HasValue);
}

/// <summary>The member's best efforts over a range, with an FTP and VO2max suggestion read from the same curve.</summary>
public sealed class GetPowerCurve(VelomineDbContext db, TimeProvider time)
    : Endpoint<PowerCurveRequest, PowerCurveResponse>
{
    public override void Configure()
    {
        Get("analytics/power-curve");
        Description(d => d.Produces<PowerCurveResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(PowerCurveRequest req, CancellationToken ct)
    {
        var clock = await MemberClock.ForAsync(db, User.UserId(), time, ct);
        await Send.OkAsync(
            await FitnessQueries.PowerCurveAsync(
                db, clock, User.UserId(), req.Days ?? 90, includeBodyMetrics: true, ct),
            ct);
    }
}

/// <summary>
/// The curve and its estimates, shared by the member's dashboard and a coach's read-only view. The coach view asks
/// for no body metrics: W/kg and VO2max reveal weight, which is not part of sharing analytics.
/// </summary>
public static class FitnessQueries
{
    private const int FtpWindowS = 1200;
    private const int FtpFallbackWindowS = 480;
    private const int Vo2MaxWindowS = 300;

    public static async Task<PowerCurveResponse> PowerCurveAsync(
        VelomineDbContext db,
        MemberClock clock,
        Guid userId,
        int days,
        bool includeBodyMetrics,
        CancellationToken ct)
    {
        var to = clock.Today;
        var from = to.AddDays(-(days - 1));

        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);

        var bestRows = await (
                from b in db.RidePowerBests.AsNoTracking()
                join r in db.Rides.AsNoTracking() on b.RideId equals r.Id
                where r.UserId == userId && r.Status == RideStatus.Ready
                    && r.StartTime >= fromUtc && r.StartTime < toUtc
                select new { b.RideId, b.DurationS, b.Watts, r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);

        var rows = bestRows
            .Where(r => r.StartTime is not null)
            .Select(r => new Row(
                r.RideId,
                r.DurationS,
                r.Watts,
                clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes)))
            .Where(r => r.LocalDate >= from && r.LocalDate <= to)
            .ToList();

        var profile = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.FtpW, u.WeightKg })
            .FirstAsync(ct);
        var weight = profile.WeightKg is > 0 ? profile.WeightKg : null;

        var points = PowerBests.Durations
            .Select(duration => new PowerCurvePoint(
                duration,
                rows.Where(r => r.DurationS == duration).Select(r => r.Watts).DefaultIfEmpty(0).Max()))
            .Where(p => p.Watts > 0)
            .ToArray();

        FtpEstimate? ftp = null;
        var best20 = Best(rows, FtpWindowS);
        var best8 = Best(rows, FtpFallbackWindowS);
        var chosen = best20 ?? best8;
        if (chosen is not null)
        {
            var method = best20 is not null ? "20min" : "8min";
            var watts = (int)Math.Round(chosen.Watts * (best20 is not null ? 0.95 : 0.90));
            ftp = new FtpEstimate(
                watts,
                method,
                chosen.LocalDate,
                includeBodyMetrics && weight is { } kg ? Math.Round(watts / kg, 1) : null);
        }

        Vo2MaxEstimate? vo2Max = null;
        var best5 = Best(rows, Vo2MaxWindowS);
        if (includeBodyMetrics && weight is { } bodyKg && best5 is not null)
        {
            vo2Max = new Vo2MaxEstimate(
                Math.Round(10.8 * (best5.Watts / bodyKg) + 7, 1),
                "5min",
                best5.LocalDate);
        }

        return new PowerCurveResponse(
            days,
            from,
            to,
            rows.Select(r => r.RideId).Distinct().Count(),
            points.Length > 0,
            profile.FtpW,
            includeBodyMetrics ? weight : null,
            points,
            ftp,
            vo2Max);
    }

    private static Row? Best(List<Row> rows, int duration) =>
        rows.Where(r => r.DurationS == duration).OrderByDescending(r => r.Watts).FirstOrDefault();

    private sealed record Row(Guid RideId, int DurationS, int Watts, DateOnly LocalDate);
}
