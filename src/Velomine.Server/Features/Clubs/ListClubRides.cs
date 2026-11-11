using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>The club's rides: what is coming, and what has just happened. A member of another club, or of none, gets 404.</summary>
public sealed class ListClubRides(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<ClubRideListResponse>
{
    /// <summary>How far back the past list goes; the calendar feed uses the same window.</summary>
    public const int PastDays = 30;

    public override void Configure()
    {
        Get("club/rides");
        Description(d => d.Produces<ClubRideListResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var now = time.GetUtcNow();
        var rides = await db.PlannedRides.AsNoTracking()
            .Include(r => r.SignUps)
            .Where(r => r.ClubId == membership.ClubId && r.StartsAt >= now.AddDays(-PastDays))
            .OrderBy(r => r.StartsAt).ThenBy(r => r.Id)
            .ToListAsync(ct);

        var routes = await CalendarQueries.SharedRoutesAsync(db, membership.ClubId, rides.Select(r => r.RouteId), ct);
        var planners = await CalendarQueries.PlannerNamesAsync(db, rides.Select(r => r.CreatedByUserId), ct);
        var summaries = rides.Select(r => CalendarQueries.Summary(r, userId, routes, planners)).ToArray();

        await Send.OkAsync(
            new ClubRideListResponse(
                [.. summaries.Where(r => r.StartsAt >= now)],
                [.. summaries.Where(r => r.StartsAt < now).Reverse()]),
            ct);
    }
}
