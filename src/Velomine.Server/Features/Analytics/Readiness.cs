using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Features.Analytics;

/// <summary>
/// F2's readiness, for today or for a past day. The endpoint, the planner (an early lighter week needs three past days)
/// and "make today easy" all read this one function, so they can never disagree. A transparent sum, not a medical
/// measure and not machine learning.
/// </summary>
public static class Readiness
{
    /// <summary>The bands' floors: 75 hard, 55 normal, 35 easy, otherwise rest (F2).</summary>
    public const int HardBand = 75;

    public const int NormalBand = 55;

    public const int EasyBand = 35;

    public const string Hard = "hard";
    public const string Normal = "normal";
    public const string Easy = "easy";
    public const string Rest = "rest";

    /// <summary>Too little history to say anything.</summary>
    public const string Unknown = "unknown";

    public static string BandOf(int score) => score switch
    {
        >= HardBand => Hard,
        >= NormalBand => Normal,
        >= EasyBand => Easy,
        _ => Rest,
    };

    /// <summary>
    /// The readiness of <paramref name="day"/>, read in the member's own calendar. Everything the score looks at is
    /// taken up to that day: the form and the ramp of that morning, the check-in of that day and the last rating
    /// before it. Today's answer is the one the endpoint gives, so <see cref="GetReadiness"/> cannot drift from it.
    /// </summary>
    public static async Task<ReadinessResponse> ForAsync(
        VelomineDbContext db,
        Guid userId,
        MemberClock clock,
        TimeProvider time,
        DateOnly day,
        CancellationToken ct)
    {
        var training = await TrainingRange.LoadAsync(db, userId, clock, time, 8, ct, endingOn: day);
        var today = training.Days[^1];
        var weekAgo = training.Days[0];

        if (training.Rides == 0 && today.Fitness <= 0 && today.Fatigue <= 0)
            return new ReadinessResponse(day, null, Unknown, false, []);

        var factors = new List<ReadinessFactor>();
        var formEffect = FormPoints(today.Form);
        factors.Add(new ReadinessFactor("form", Math.Round(today.Form, 1), Math.Round(formEffect, 1)));

        var ramp = today.Fitness - weekAgo.Fitness;
        var rampEffect = RampPoints(ramp);
        factors.Add(new ReadinessFactor("ramp", Math.Round(ramp, 1), Math.Round(rampEffect, 1)));

        var recentLoad = today.Load + (training.Days.Length > 1 ? training.Days[^2].Load : 0);
        var recentEffect = recentLoad > 200 ? -5.0 : 0.0;
        factors.Add(new ReadinessFactor("recentLoad", Math.Round(recentLoad, 1), recentEffect));

        var hasWellbeing = false;
        if (await WellbeingRules.HasConsentAsync(db, userId, ct))
        {
            var checkIn = await db.DailyCheckIns.AsNoTracking()
                .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == day, ct);
            if (checkIn is not null)
            {
                hasWellbeing = true;
                // Sleep is one of Hooper's four: it joins the average when the check-in has it.
                var good = checkIn.Sleep is { } sleep
                    ? (checkIn.Mood + checkIn.Motivation + sleep
                        + (6 - checkIn.Fatigue) + (6 - checkIn.Soreness) + (6 - checkIn.Stress)) / 6.0
                    : (checkIn.Mood + checkIn.Motivation
                        + (6 - checkIn.Fatigue) + (6 - checkIn.Soreness) + (6 - checkIn.Stress)) / 5.0;
                factors.Add(new ReadinessFactor("wellbeing", Math.Round(good, 1), Math.Round((good - 3) * 10, 1)));
            }
        }

        // The last rating of that day: now for today, and for a past day the ones within two days of its end.
        var until = day == clock.Today
            ? time.GetUtcNow()
            : new DateTimeOffset(TimeZoneInfo.ConvertTimeToUtc(day.AddDays(1).ToDateTime(TimeOnly.MinValue), clock.Zone), TimeSpan.Zero);
        var feels = db.RideFeels.AsNoTracking()
            .Join(db.Rides.AsNoTracking().Where(r => r.UserId == userId && r.Status == RideStatus.Ready
                    && r.StartTime >= until.AddHours(-48)),
                f => f.RideId, r => r.Id, (f, r) => new { f.Rpe, r.StartTime });
        if (day != clock.Today) feels = feels.Where(f => f.StartTime < until);
        var recentFeel = await feels.OrderByDescending(f => f.StartTime).FirstOrDefaultAsync(ct);
        if (recentFeel is not null)
        {
            var rpeEffect = recentFeel.Rpe >= 8 ? -8.0 : recentFeel.Rpe <= 4 ? 4.0 : 0.0;
            factors.Add(new ReadinessFactor("rpe", recentFeel.Rpe, rpeEffect));
        }

        var score = (int)Math.Round(Math.Clamp(50 + factors.Sum(f => f.Effect), 0, 100));
        return new ReadinessResponse(day, score, BandOf(score), hasWellbeing, [.. factors]);
    }

    private static double FormPoints(double form) =>
        -25 + 45 * Math.Clamp((form + 30) / 50, 0, 1);

    private static double RampPoints(double ramp) =>
        ramp >= 0 ? -Math.Min(ramp, 10) : Math.Min(-ramp, 5);
}
