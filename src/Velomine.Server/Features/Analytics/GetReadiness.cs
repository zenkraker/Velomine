using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Features.Analytics;

/// <summary>One input to the readiness score. Keys are localized by the app; values and effects are numbers.</summary>
public sealed record ReadinessFactor(string Key, double Value, double Effect);

/// <summary>
/// Today's readiness. <see cref="Band"/> is "hard", "normal", "easy", "rest" or "unknown" when there is too little
/// history. The app turns the band and the factors into sentences, so the server never sends prose.
/// </summary>
public sealed record ReadinessResponse(
    DateOnly Date,
    int? Score,
    string Band,
    bool HasWellbeing,
    ReadinessFactor[] Factors);

/// <summary>
/// A transparent readiness score from form, seven-day ramp and recent load, adjusted by today's check-in and the
/// last ride's RPE when they exist. Not a medical measure and not machine learning.
/// </summary>
public sealed class GetReadiness(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<ReadinessResponse>
{
    public override void Configure()
    {
        Get("analytics/readiness");
        Description(d => d.Produces<ReadinessResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var training = await TrainingRange.LoadAsync(db, userId, clock, 8, ct);
        var today = training.Days[^1];
        var weekAgo = training.Days[0];

        if (training.Rides == 0 && today.Fitness <= 0 && today.Fatigue <= 0)
        {
            await Send.OkAsync(new ReadinessResponse(clock.Today, null, "unknown", false, []), ct);
            return;
        }

        var factors = new List<ReadinessFactor>();
        var formEffect = FormPoints(today.Form);
        factors.Add(new ReadinessFactor("form", Math.Round(today.Form, 1), Math.Round(formEffect, 1)));

        var ramp = today.Fitness - weekAgo.Fitness;
        var rampEffect = RampPoints(ramp);
        factors.Add(new ReadinessFactor("ramp", Math.Round(ramp, 1), Math.Round(rampEffect, 1)));

        var recentLoad = today.Tss + (training.Days.Length > 1 ? training.Days[^2].Tss : 0);
        var recentEffect = recentLoad > 200 ? -5.0 : 0.0;
        factors.Add(new ReadinessFactor("recentLoad", Math.Round(recentLoad, 1), recentEffect));

        var hasWellbeing = false;
        if (await WellbeingRules.HasConsentAsync(db, userId, ct))
        {
            var checkIn = await db.DailyCheckIns.AsNoTracking()
                .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == clock.Today, ct);
            if (checkIn is not null)
            {
                hasWellbeing = true;
                var good = (checkIn.Mood + checkIn.Motivation
                    + (6 - checkIn.Fatigue) + (6 - checkIn.Soreness) + (6 - checkIn.Stress)) / 5.0;
                factors.Add(new ReadinessFactor("wellbeing", Math.Round(good, 1), Math.Round((good - 3) * 10, 1)));
            }
        }

        var recentFeel = await (
                from f in db.RideFeels.AsNoTracking()
                join r in db.Rides.AsNoTracking() on f.RideId equals r.Id
                where r.UserId == userId && r.Status == RideStatus.Ready
                    && r.StartTime >= time.GetUtcNow().AddHours(-48)
                orderby r.StartTime descending
                select new { f.Rpe })
            .FirstOrDefaultAsync(ct);
        if (recentFeel is not null)
        {
            var rpeEffect = recentFeel.Rpe >= 8 ? -8.0 : recentFeel.Rpe <= 4 ? 4.0 : 0.0;
            factors.Add(new ReadinessFactor("rpe", recentFeel.Rpe, rpeEffect));
        }

        var score = (int)Math.Round(Math.Clamp(50 + factors.Sum(f => f.Effect), 0, 100));
        await Send.OkAsync(new ReadinessResponse(
            clock.Today,
            score,
            BandOf(score),
            hasWellbeing,
            [.. factors]), ct);
    }

    private static double FormPoints(double form) =>
        -25 + 45 * Math.Clamp((form + 30) / 50, 0, 1);

    private static double RampPoints(double ramp) =>
        ramp >= 0 ? -Math.Min(ramp, 10) : Math.Min(-ramp, 5);

    private static string BandOf(int score) => score switch
    {
        >= 75 => "hard",
        >= 55 => "normal",
        >= 35 => "easy",
        _ => "rest",
    };
}
