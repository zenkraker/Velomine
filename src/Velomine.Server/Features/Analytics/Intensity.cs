using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>Seconds in each of Seiler's three zones. <see cref="Rides"/> is 0 when no ride contributed.</summary>
public sealed record IntensityTotals(double EasyS, double ModerateS, double HardS, int Rides);

/// <summary>Seiler's three zones over a range, and the label they add up to (Treff et al. 2019).</summary>
public sealed record IntensityResponse(
    double EasyS,
    double ModerateS,
    double HardS,
    double EasyPct,
    double ModeratePct,
    double HardPct,
    double? PolarisationIndex,
    string Label,
    int Rides);

/// <summary>One week of the range: seconds in each zone. No label, because a week is a share, not a plan.</summary>
public sealed record IntensityWeek(DateOnly WeekStart, double EasyS, double ModerateS, double HardS);

/// <summary>
/// How riding splits into easy, moderate and hard (Seiler's three zones, Treff et al. 2019). Worked out on every
/// request from the current profile: power zones when the ride has power and the member an FTP, heart-rate zones
/// otherwise. A ride with neither signal adds nothing.
/// </summary>
public static class Intensity
{
    /// <summary>Below this share of moderate riding the index is undefined, not huge.</summary>
    private const double MinModeratePct = 0.1;

    public static async Task<(IntensityResponse? Totals, IntensityWeek[] Weeks)> LoadAsync(
        VelomineDbContext db,
        Guid userId,
        MemberClock clock,
        TimeProvider time,
        DateOnly from,
        DateOnly to,
        CancellationToken ct,
        RideFilter filter = default,
        PrivacyProfile? viewer = null)
    {
        var profile = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.FtpW, u.BirthYear })
            .FirstAsync(ct);
        var maxHeartRate = User.EstimateMaxHeartRate(profile.BirthYear, time);

        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var query = db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime >= fromUtc && r.StartTime < toUtc);
        var rides = await filter.Apply(query)
            .Select(r => new
            {
                r.StartTime,
                r.UtcOffsetMinutes,
                r.HidePower,
                r.HideHeartRate,
                r.Streams!.Time,
                r.Streams.HeartRate,
                r.Streams.Power,
            })
            .ToListAsync(ct);

        var totals = new Dictionary<DateOnly, IntensityTotals>();
        foreach (var ride in rides)
        {
            var start = ride.StartTime!.Value;
            var date = clock.LocalDateOf(start, ride.UtcOffsetMinutes);
            // The training range reads two days either side to find its exact local cut; the split only ever counts
            // the range itself, which is what the caller sums TSS over.
            // Totals and the split count the same rides, so they always add up.
            if (date < from || date >= to) continue;

            // A coach sees a ride through its privacy snapshot: power hidden falls back to heart rate, and both
            // hidden means the ride says nothing.
            var hidePower = viewer is not null && (ride.HidePower ?? viewer.HidePower);
            var hideHeartRate = viewer is not null && (ride.HideHeartRate ?? viewer.HideHeartRate);
            var power = hidePower ? null : ride.Power;
            var heartRate = hideHeartRate ? null : ride.HeartRate;

            var split = FromPower(power, ride.Time, profile.FtpW)
                ?? FromHeartRate(heartRate, ride.Time, maxHeartRate);
            if (split is { } zoneTime) Add(totals, date, zoneTime);
        }

        if (totals.Count == 0) return (null, []);

        var sum = new IntensityTotals(
            totals.Values.Sum(t => t.EasyS),
            totals.Values.Sum(t => t.ModerateS),
            totals.Values.Sum(t => t.HardS),
            totals.Values.Sum(t => t.Rides));
        var (easyPct, moderatePct, hardPct) = Percentages(sum);
        var weeks = totals
            .GroupBy(t => Periods.StartOf(t.Key, Periods.Week, clock.FirstDayOfWeek))
            .OrderBy(g => g.Key)
            .Select(g => new IntensityWeek(
                g.Key,
                Math.Round(g.Sum(t => t.Value.EasyS)),
                Math.Round(g.Sum(t => t.Value.ModerateS)),
                Math.Round(g.Sum(t => t.Value.HardS))))
            .ToArray();

        return (new IntensityResponse(
            Math.Round(sum.EasyS),
            Math.Round(sum.ModerateS),
            Math.Round(sum.HardS),
            easyPct,
            moderatePct,
            hardPct,
            PolarisationIndex(easyPct, moderatePct, hardPct),
            Label(easyPct, moderatePct, hardPct),
            sum.Rides), weeks);
    }

    /// <summary>
    /// Easy is below 75 % of FTP, moderate from 75 % to below 105 %, hard from 105 %. Null without both. The rows are
    /// the stored 1 Hz streams, whose times leave out pauses.
    /// </summary>
    public static IntensityTotals? FromPower(IReadOnlyList<short?>? power, IReadOnlyList<double> time, int? ftpW)
    {
        if (power is null || ftpW is not { } ftp || ftp <= 0) return null;
        // A ride whose power never rises above 0 W has no training time to split.
        if (!power.Any(p => p is > 0)) return null;
        var zones = TrainingLoad.ZoneSeconds(power, time, ftp, 0, TrainingLoad.PowerBounds);
        return zones.Sum() > 0
            ? new IntensityTotals(zones[0] + zones[1], zones[2] + zones[3], zones[4] + zones[5] + zones[6], 1)
            : null;
    }

    /// <summary>Easy is below 80 % of maximum heart rate, moderate from 80 % to below 90 %, hard from 90 %. Null without both.</summary>
    public static IntensityTotals? FromHeartRate(IReadOnlyList<short?>? heartRate, IReadOnlyList<double> time, int? maxHeartRate)
    {
        if (heartRate is null || maxHeartRate is not { } max || max <= 0) return null;
        // Heart-rate zones count from 1 bpm, so anything below 50 % of maximum (resting) is in zone 1. It is not
        // training time: an easy minute would otherwise be exactly as easy as sitting still.
        var zones = TrainingLoad.ZoneSeconds(heartRate, time, max, 0, TrainingLoad.HeartRateBounds);
        return zones.Sum() > 0
            ? new IntensityTotals(zones[0] + zones[1] + zones[2], zones[3], zones[4], 1)
            : null;
    }

    /// <summary>The three shares of the zone time, to one decimal, so they add up to 100.</summary>
    public static (double Easy, double Moderate, double Hard) Percentages(IntensityTotals totals)
    {
        var total = totals.EasyS + totals.ModerateS + totals.HardS;
        if (total <= 0) return (0, 0, 0);
        var easy = Math.Round(totals.EasyS / total * 100, 1);
        var hard = Math.Round(totals.HardS / total * 100, 1);
        // A tiny share can round to zero; then the log of it is not a number.
        return (easy, Math.Round(100 - easy - hard, 1), hard);
    }

    /// <summary>
    /// log10 of easy × hard over moderate, percentages 0–100, two decimals. Null when there is no hard time or
    /// almost no moderate time: the ratio has no meaning there.
    /// </summary>
    public static double? PolarisationIndex(double easyPct, double moderatePct, double hardPct) =>
        moderatePct < MinModeratePct || hardPct == 0
            ? null
            : RoundIndex(Math.Log10(easyPct * hardPct / moderatePct));

    /// <summary>
    /// The same idea with easy and hard taken together, as Domestique's additive index. Rule 1 of the label uses
    /// it; the API never returns it.
    /// </summary>
    public static double? TwoPoleIndex(double easyPct, double moderatePct, double hardPct) =>
        moderatePct < MinModeratePct
            ? null
            : RoundIndex(Math.Log10((easyPct + hardPct) / moderatePct));

    /// <summary>
    /// The distribution labels of Treff et al. 2019, first match wins. A polarised week needs a real hard pole, not
    /// only a high index: 80 % easy with 15 % hard is base riding with some efforts.
    /// </summary>
    public static string Label(double easyPct, double moderatePct, double hardPct)
    {
        var twoPole = TwoPoleIndex(easyPct, moderatePct, hardPct);
        var index = PolarisationIndex(easyPct, moderatePct, hardPct);

        if (twoPole > 2.00 && easyPct > hardPct && hardPct > moderatePct) return Labels.Polarised;
        if (index > 2.00 && hardPct >= 20 && moderatePct < hardPct) return Labels.Polarised;
        if (hardPct > 40 && easyPct < 20) return Labels.Hiit;
        if (moderatePct >= 30 && hardPct <= 15 && easyPct <= 50) return Labels.Threshold;
        if (moderatePct >= 35 && moderatePct > hardPct + 10) return Labels.Pyramidal;
        if (easyPct >= 70) return Labels.Base;
        if (moderatePct >= 20 && moderatePct > hardPct && easyPct is >= 40 and < 70) return Labels.Pyramidal;
        return Labels.Mixed;
    }

    /// <summary>Two decimals. A share that rounds to 0.1 can still log to −Infinity, which is not a number JSON can carry.</summary>
    private static double? RoundIndex(double value) => double.IsFinite(value) ? Math.Round(value, 2) : null;

    private static void Add(Dictionary<DateOnly, IntensityTotals> totals, DateOnly date, IntensityTotals ride) =>
        totals[date] = totals.TryGetValue(date, out var day)
            ? day with
            {
                EasyS = day.EasyS + ride.EasyS,
                ModerateS = day.ModerateS + ride.ModerateS,
                HardS = day.HardS + ride.HardS,
                Rides = day.Rides + 1,
            }
            : ride;
}

public static class Labels
{
    public const string Polarised = "polarised";
    public const string Pyramidal = "pyramidal";
    public const string Threshold = "threshold";
    public const string Hiit = "hiit";
    public const string Base = "base";
    public const string Mixed = "mixed";

    public static readonly string[] All = [Polarised, Pyramidal, Threshold, Hiit, Base, Mixed];
}
