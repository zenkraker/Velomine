using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Coach;

public sealed record CoachAthleteResponse(
    Guid UserId,
    string DisplayName,
    bool SharesRides,
    bool SharesAnalytics,
    bool SharesRoutes,
    DateTimeOffset? LastRideAt,
    int Rides,
    double DistanceM,
    double Tss7,
    double Tss42);

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
            .Where(g => g.ClubId == req.ClubId && (g.DataType == DataTypes.Rides || g.DataType == DataTypes.Analytics))
            .ToListAsync(ct);
        var athleteIds = grants.Select(g => g.MemberId).Where(id => id != viewerId).Distinct().ToList();
        var members = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.User)
            .Where(m => m.ClubId == req.ClubId && athleteIds.Contains(m.UserId))
            .ToListAsync(ct);

        var athletes = new List<CoachAthleteResponse>(members.Count);
        foreach (var member in members)
            athletes.Add(await CoachQueries.SummaryAsync(db, time, member, grants, ct));

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
        var grants = await db.ShareGrants.AsNoTracking()
            .Where(g => g.ClubId == req.ClubId && g.MemberId == req.UserId)
            .ToListAsync(ct);
        if (member is null || !await SharingRules.IsCoachAsync(db, req.ClubId, viewerId, ct) ||
            grants.All(g => g.DataType is not (DataTypes.Rides or DataTypes.Analytics)))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var summary = await CoachQueries.SummaryAsync(db, time, member, grants, ct);
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

    public static async Task<CoachAthleteResponse> SummaryAsync(
        VelomineDbContext db,
        TimeProvider time,
        ClubMembership member,
        IReadOnlyCollection<ShareGrant> grants,
        CancellationToken ct)
    {
        var clock = await MemberClock.ForAsync(db, member.UserId, time, ct);
        var ftpW = await db.Users.AsNoTracking()
            .Where(u => u.Id == member.UserId)
            .Select(u => u.FtpW)
            .FirstAsync(ct);
        var from = clock.Today.AddDays(-41);
        var rides = await RideDays.LoadAsync(db, member.UserId, clock, from, clock.Today.AddDays(1), ct, ftpW: ftpW);
        var week = rides.Where(r => r.LocalDate >= clock.Today.AddDays(-6)).ToList();
        var lastRideAt = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == member.UserId && r.Status == RideStatus.Ready)
            .MaxAsync(r => (DateTimeOffset?)r.StartTime, ct);

        return new CoachAthleteResponse(
            member.UserId,
            member.User.DisplayName,
            grants.Any(g => g.DataType == DataTypes.Rides),
            grants.Any(g => g.DataType == DataTypes.Analytics),
            grants.Any(g => g.DataType == DataTypes.Routes),
            lastRideAt,
            rides.Count,
            rides.Sum(r => r.DistanceM),
            Math.Round(week.Sum(r => r.Tss), 1),
            Math.Round(rides.Sum(r => r.Tss), 1));
    }
}
