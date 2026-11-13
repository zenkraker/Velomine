using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Coach;

public sealed record CoachAthleteResponse(
    Guid UserId,
    string DisplayName,
    bool SharesRides,
    bool SharesAnalytics,
    bool SharesRoutes,
    bool SharesWellbeing,
    DateTimeOffset? LastRideAt,
    int? Rides,
    double? DistanceM,
    double? Tss7,
    double? Tss42);

public sealed record CoachAthletesResponse(CoachAthleteResponse[] Athletes);

public sealed class CoachClubRequest
{
    public Guid ClubId { get; set; }
}

public sealed class CoachAthleteRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }
}

/// <summary>Who a coach may look at: members of the same club who shared rides or training.</summary>
public sealed class ListCoachAthletes(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachClubRequest, CoachAthletesResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes");
        Description(d => d.Produces<CoachAthletesResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachClubRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.IsCoachAsync(db, req.ClubId, viewerId, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var grants = await db.ShareGrants.AsNoTracking()
            .Where(g => g.ClubId == req.ClubId)
            .ToListAsync(ct);
        var athleteIds = grants
            .Where(g => g.DataType is DataTypes.Rides or DataTypes.Analytics or DataTypes.Wellbeing)
            .Select(g => g.MemberId)
            .Where(id => id != viewerId)
            .Distinct()
            .ToList();
        var members = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.User)
            .Where(m => m.ClubId == req.ClubId && athleteIds.Contains(m.UserId))
            .ToListAsync(ct);

        var athletes = new List<CoachAthleteResponse>(members.Count);
        var sharing = members
            .Where(member => grants.Any(g => g.MemberId == member.UserId
                && g.DataType is DataTypes.Rides or DataTypes.Analytics or DataTypes.Wellbeing))
            .ToList();
        athletes.AddRange(await CoachQueries.SummariesAsync(db, time, sharing, grants, ct));

        // Hiding power takes the training load with it, even on the roster.
        var privacy = await PrivacyRules.LoadManyAsync(db, athletes.Select(a => a.UserId).ToList(), ct);
        athletes = [.. athletes.Select(a => privacy[a.UserId].HidePower ? a with { Tss7 = null, Tss42 = null } : a)];

        // The roster shows each athlete's snapshot, so it is a view of their data, not just a directory.
        await SharingRules.RecordViewsAsync(
            db, time, athletes.Select(a => a.UserId), req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.Summary, ct);
        await Send.OkAsync(new CoachAthletesResponse([.. athletes.OrderBy(a => a.DisplayName, StringComparer.OrdinalIgnoreCase)]), ct);
    }
}

/// <summary>One athlete's shared summary, for the coach's athlete page.</summary>
public sealed class GetCoachAthlete(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachAthleteRequest, CoachAthleteResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}");
        Description(d => d.Produces<CoachAthleteResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachAthleteRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        var member = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.ClubId == req.ClubId && m.UserId == req.UserId, ct);
        var canRides = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct);
        var canAnalytics = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Analytics, ct);
        var canWellbeing = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Wellbeing, ct);
        if (member is null || (!canRides && !canAnalytics && !canWellbeing))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var grants = await db.ShareGrants.AsNoTracking()
            .Where(g => g.ClubId == req.ClubId && g.MemberId == req.UserId)
            .ToListAsync(ct);
        var summary = await CoachQueries.SummaryAsync(db, time, member, grants, ct);
        var privacy = await PrivacyRules.LoadCurrentAsync(db, req.UserId, ct);
        if (privacy.HidePower) summary = summary with { Tss7 = null, Tss42 = null };
        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId, await CoachQueries.ViewerNameAsync(db, viewerId, ct),
            ViewKinds.Summary, ct);
        await Send.OkAsync(summary, ct);
    }
}

public sealed class CoachTrainingRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    /// <summary>How many days to show, ending today: 7 to 730, default 90.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

public sealed class CoachTrainingValidator : Validator<CoachTrainingRequest>
{
    public CoachTrainingValidator() => RuleFor(x => x.Days).InclusiveBetween(7, 730).When(x => x.Days.HasValue);
}

/// <summary>The athlete's training load over a range, the same numbers the athlete sees on their own dashboard.</summary>
public sealed class GetCoachTraining(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachTrainingRequest, TrainingResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/training");
        Description(d => d.Produces<TrainingResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachTrainingRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Analytics, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, req.UserId, time, ct);
        // Fitness, fatigue and form are built from TSS and TRIMP: hiding either stream hides the trend.
        var privacy = await PrivacyRules.LoadCurrentAsync(db, req.UserId, ct);
        if (privacy.HidesPowerOrHeartRate)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId, await CoachQueries.ViewerNameAsync(db, viewerId, ct),
            ViewKinds.Training, ct);
        await Send.OkAsync(await TrainingRange.LoadAsync(db, req.UserId, clock, req.Days ?? 90, ct), ct);
    }
}

public static class CoachQueries
{
    public static async Task<string> ViewerNameAsync(VelomineDbContext db, Guid viewerId, CancellationToken ct) =>
        await db.Users.AsNoTracking().Where(u => u.Id == viewerId).Select(u => u.DisplayName).FirstOrDefaultAsync(ct) ?? "";

    /// <summary>
    /// The roster in a fixed number of queries: one for the rides of every athlete, one for their last ride.
    /// Each member's own grants still decide what is shown for them.
    /// </summary>
    public static async Task<List<CoachAthleteResponse>> SummariesAsync(
        VelomineDbContext db,
        TimeProvider time,
        IReadOnlyCollection<ClubMembership> members,
        IReadOnlyCollection<ShareGrant> grants,
        CancellationToken ct)
    {
        if (members.Count == 0) return [];

        var ids = members.Select(m => m.UserId).ToList();
        // The local window is the same 42 days for everyone; the UTC cut has a day either side for time zones.
        var utcToday = DateOnly.FromDateTime(time.GetUtcNow().UtcDateTime);
        var fromUtc = new DateTimeOffset(utcToday.AddDays(-42).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(utcToday.AddDays(2).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rides = await db.Rides.AsNoTracking()
            .Where(r => ids.Contains(r.UserId) && r.Status == RideStatus.Ready
                && r.StartTime >= fromUtc && r.StartTime < toUtc)
            .Select(r => new { r.UserId, r.StartTime, r.UtcOffsetMinutes, r.DistanceM, r.MovingS, r.ElevationGainM, r.NormalizedPowerW, r.Tss })
            .ToListAsync(ct);

        var rideSharerIds = members
            .Where(m => grants.Any(g => g.MemberId == m.UserId && g.DataType == DataTypes.Rides))
            .Select(m => m.UserId)
            .ToList();
        var lastRideTimes = rideSharerIds.Count == 0
            ? new Dictionary<Guid, DateTimeOffset?>()
            : await db.Rides.AsNoTracking()
                .Where(r => rideSharerIds.Contains(r.UserId) && r.Status == RideStatus.Ready)
                .GroupBy(r => r.UserId)
                .Select(g => new { UserId = g.Key, Last = g.Max(r => r.StartTime) })
                .ToDictionaryAsync(x => x.UserId, x => x.Last, ct);

        var result = new List<CoachAthleteResponse>(members.Count);
        foreach (var member in members)
        {
            var memberGrants = grants.Where(g => g.MemberId == member.UserId).ToList();
            var sharesRides = memberGrants.Any(g => g.DataType == DataTypes.Rides);
            var sharesAnalytics = memberGrants.Any(g => g.DataType == DataTypes.Analytics);
            var sharesRoutes = memberGrants.Any(g => g.DataType == DataTypes.Routes);
            var sharesWellbeing = memberGrants.Any(g => g.DataType == DataTypes.Wellbeing);

            var clock = MemberClock.For(member.User.TimeZone, member.User.FirstDayOfWeek, time);
            var from = clock.Today.AddDays(-41);
            var to = clock.Today.AddDays(1);
            var memberRides = rides
                .Where(r => r.UserId == member.UserId)
                .Select(r => new RideDay(
                    clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes),
                    r.DistanceM ?? 0,
                    r.MovingS ?? 0,
                    r.ElevationGainM ?? 0,
                    r.Tss ?? TrainingLoad.PowerLoad(r.NormalizedPowerW, r.MovingS ?? 0, member.User.FtpW).Tss ?? 0))
                .Where(r => r.LocalDate >= from && r.LocalDate < to)
                .ToList();
            var week = memberRides.Where(r => r.LocalDate >= clock.Today.AddDays(-6)).ToList();

            result.Add(new CoachAthleteResponse(
                member.UserId,
                member.User.DisplayName,
                sharesRides,
                sharesAnalytics,
                sharesRoutes,
                sharesWellbeing,
                sharesRides && lastRideTimes.TryGetValue(member.UserId, out var last) ? last : null,
                sharesRides ? memberRides.Count : null,
                sharesRides ? memberRides.Sum(r => r.DistanceM) : null,
                sharesAnalytics ? Math.Round(week.Sum(r => r.Tss), 1) : null,
                sharesAnalytics ? Math.Round(memberRides.Sum(r => r.Tss), 1) : null));
        }

        return result;
    }

    public static async Task<CoachAthleteResponse> SummaryAsync(
        VelomineDbContext db,
        TimeProvider time,
        ClubMembership member,
        IReadOnlyCollection<ShareGrant> grants,
        CancellationToken ct)
    {
        var sharesRides = grants.Any(g => g.DataType == DataTypes.Rides);
        var sharesAnalytics = grants.Any(g => g.DataType == DataTypes.Analytics);
        var sharesRoutes = grants.Any(g => g.DataType == DataTypes.Routes);
        var sharesWellbeing = grants.Any(g => g.DataType == DataTypes.Wellbeing);

        var ftpW = await db.Users.AsNoTracking()
            .Where(u => u.Id == member.UserId)
            .Select(u => u.FtpW)
            .FirstAsync(ct);
        var clock = await MemberClock.ForAsync(db, member.UserId, time, ct);
        var rides = await RideDays.LoadAsync(
            db,
            member.UserId,
            clock,
            clock.Today.AddDays(-41),
            clock.Today.AddDays(1),
            ct,
            ftpW: ftpW);

        // Each number exists only for the kind of data the member shared: no ride dates or counts to a coach
        // who was given training but not rides, and no training load to one given only rides.
        var lastRideAt = sharesRides
            ? await db.Rides.AsNoTracking()
                .Where(r => r.UserId == member.UserId && r.Status == RideStatus.Ready)
                .MaxAsync(r => (DateTimeOffset?)r.StartTime, ct)
            : null;
        var week = rides.Where(r => r.LocalDate >= clock.Today.AddDays(-6)).ToList();

        return new CoachAthleteResponse(
            member.UserId,
            member.User.DisplayName,
            sharesRides,
            sharesAnalytics,
            sharesRoutes,
            sharesWellbeing,
            lastRideAt,
            sharesRides ? rides.Count : null,
            sharesRides ? rides.Sum(r => r.DistanceM) : null,
            sharesAnalytics ? Math.Round(week.Sum(r => r.Tss), 1) : null,
            sharesAnalytics ? Math.Round(rides.Sum(r => r.Tss), 1) : null);
    }
}
