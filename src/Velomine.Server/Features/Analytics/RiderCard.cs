using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Features.Analytics;

/// <summary>One best effort of the last 90 days: the window, the watts and the ride they came from.</summary>
public sealed record RiderCardBest(int Seconds, int? Watts, Guid? RideId, DateOnly? Date);

/// <summary>
/// The rider's own numbers on one card, each with where it came from: the FTP and the two heart rates from the profile,
/// critical power, W′ and peak power from the power curve, the best efforts with their rides, the efficiency factor by
/// week, the last 90 days of riding, today's fitness and form from the effort score, and the next event. Nothing is
/// stored; a number the rider does not have is null.
/// </summary>
public sealed record RiderCardResponse(
    int? FtpW,
    double? WeightKg,
    double? WattsPerKg,
    string? FtpSource,
    DateTimeOffset? FtpSetAt,
    Guid? FtpRideId,
    DateOnly? FtpRideDate,
    int? CriticalPowerW,
    int? WPrimeJ,
    int? PeakPowerW,
    RiderCardBest[] Bests,
    int? MaxHeartRate,
    string? MaxHeartRateSource,
    DateTimeOffset? MaxHeartRateSetAt,
    Guid? MaxHeartRateRideId,
    DateOnly? MaxHeartRateRideDate,
    int? ThresholdHeartRate,
    string? ThresholdHeartRateSource,
    DateTimeOffset? ThresholdHeartRateSetAt,
    Guid? ThresholdHeartRateRideId,
    DateOnly? ThresholdHeartRateRideDate,
    /// <summary>The mean efficiency factor of each of the last eight weeks that had steady rides.</summary>
    EfficiencyWeek[] Efficiency,
    int Rides,
    double DistanceM,
    double MovingS,
    double ElevationGainM,
    double? Fitness,
    double? Fatigue,
    double? Form,
    EventResponse? NextEvent);

/// <summary>
/// The rider card, worked out on every request from the rides, the power bests, the profile and the calendar. Owner
/// only: it takes no user id, so it can only ever answer with the caller's own numbers. Estimated watts feed no row.
/// </summary>
public sealed class GetRiderCard(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<RiderCardResponse>
{
    private const int WindowDays = 90;
    private const int EfficiencyWeeks = 8;

    /// <summary>The windows the card lists: 5 s, 1 min, 5 min and 20 min.</summary>
    public static readonly int[] BestDurations = [5, 60, 300, 1200];

    public override void Configure()
    {
        Get("analytics/rider-card");
        Description(d => d.Produces<RiderCardResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var to = clock.Today;
        var from = to.AddDays(-(WindowDays - 1));

        var profile = await GetProfile.ProfileOfAsync(db, user, time, ct);
        var critical = await FitnessQueries.CriticalPowerAsync(db, clock, userId, ct);
        var bests = await BestsAsync(db, clock, userId, from, to, ct);
        var efficiency = await Efficiency.LoadAsync(
            db, userId, clock, to.AddDays(-(EfficiencyWeeks * 7 - 1)), to.AddDays(1), ct);
        var days = await RideDays.LoadAsync(db, userId, clock, from, to.AddDays(1), ct);
        // Fitness and form today come from the same range the dashboard draws, so the two never disagree.
        var today = (await TrainingRange.LoadAsync(db, userId, clock, time, 1, ct)).Days[^1];
        var next = await db.Events.AsNoTracking()
            .Where(e => e.UserId == userId && e.Date >= to)
            .OrderBy(e => e.Date).ThenBy(e => e.Id)
            .FirstOrDefaultAsync(ct);
        var rideDates = await RideDatesAsync(
            db, clock, [profile.FtpRideId, profile.MaxHeartRateRideId, profile.ThresholdHeartRateRideId], ct);

        await Send.OkAsync(new RiderCardResponse(
            profile.FtpW,
            profile.WeightKg,
            profile.FtpW is { } ftp && profile.WeightKg is { } kg and > 0 ? Math.Round(ftp / kg, 1) : null,
            profile.FtpSource,
            profile.FtpSetAt,
            profile.FtpRideId,
            DateOf(rideDates, profile.FtpRideId),
            critical?.CpW,
            critical?.WPrimeJ,
            critical?.PeakW,
            bests,
            profile.MaxHeartRate,
            profile.MaxHeartRateSource,
            profile.MaxHeartRateSetAt,
            profile.MaxHeartRateRideId,
            DateOf(rideDates, profile.MaxHeartRateRideId),
            profile.ThresholdHeartRate,
            profile.ThresholdHeartRateSource,
            profile.ThresholdHeartRateSetAt,
            profile.ThresholdHeartRateRideId,
            DateOf(rideDates, profile.ThresholdHeartRateRideId),
            efficiency,
            days.Count,
            Math.Round(days.Sum(d => d.DistanceM), 1),
            Math.Round(days.Sum(d => d.MovingS), 1),
            Math.Round(days.Sum(d => d.ElevationGainM), 1),
            today.Fitness,
            today.Fatigue,
            today.Form,
            next is null ? null : EventResponse.From(next)), ct);
    }

    /// <summary>The best of each listed window in the range, with the ride it came from; null when there is none.</summary>
    private static async Task<RiderCardBest[]> BestsAsync(
        VelomineDbContext db, MemberClock clock, Guid userId, DateOnly from, DateOnly to, CancellationToken ct)
    {
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(to.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var durations = BestDurations;
        var rows = await (
                from b in db.RidePowerBests.AsNoTracking()
                join r in db.Rides.AsNoTracking() on b.RideId equals r.Id
                where r.UserId == userId && r.Status == RideStatus.Ready
                    && r.StartTime >= fromUtc && r.StartTime < toUtc
                    && durations.Contains(b.DurationS)
                select new { b.DurationS, b.Watts, b.RideId, r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);

        var counted = rows
            .Where(r => r.StartTime is not null)
            .Select(r => (r.DurationS, r.Watts, r.RideId, Date: clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes)))
            .Where(r => r.Date >= from && r.Date <= to);

        return
        [
            .. durations.Select(duration =>
            {
                // The same watts on two rides: the newer one is the one the card opens.
                if (counted.Where(r => r.DurationS == duration)
                        .OrderByDescending(r => r.Watts).ThenByDescending(r => r.Date)
                        .FirstOrDefault() is not { Watts: > 0 } best)
                    return new RiderCardBest(duration, null, null, null);
                return new RiderCardBest(duration, best.Watts, best.RideId, best.Date);
            }),
        ];
    }

    /// <summary>The local days of the given rides, so a note can date the ride a number came from.</summary>
    private static async Task<Dictionary<Guid, DateOnly>> RideDatesAsync(
        VelomineDbContext db, MemberClock clock, Guid?[] ids, CancellationToken ct)
    {
        var wanted = ids.OfType<Guid>().Distinct().ToArray();
        if (wanted.Length == 0) return [];
        var rides = await db.Rides.AsNoTracking()
            .Where(r => wanted.Contains(r.Id))
            .Select(r => new { r.Id, r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);
        return rides
            .Where(r => r.StartTime is not null)
            .ToDictionary(r => r.Id, r => clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes));
    }

    private static DateOnly? DateOf(Dictionary<Guid, DateOnly> dates, Guid? rideId) =>
        rideId is { } id ? dates.GetValueOrDefault(id) : null;
}
