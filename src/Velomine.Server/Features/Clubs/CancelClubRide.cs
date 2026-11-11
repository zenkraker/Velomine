using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

/// <summary>
/// Cancels a ride: it stays on the calendar, marked cancelled, so nobody rides to the meeting point for nothing. The
/// riders who are in are told; cancelling twice says nothing twice. A route withdrawn later never cancels or notifies.
/// </summary>
public sealed class CancelClubRide(VelomineDbContext db, TimeProvider time)
    : Endpoint<ClubRideIdRequest, ClubRideDetailResponse>
{
    public override void Configure()
    {
        Post("club/rides/{id}/cancel");
        Description(d => d.Produces<ClubRideDetailResponse>(200).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ClubRideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var ride = await CalendarQueries.RideAsync(db, membership.ClubId, req.Id, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        // Another club never learns this ride exists; a rider in this one is simply not allowed to cancel it.
        if (!CalendarQueries.CanPlan(membership.Role))
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        if (ride.CancelledAt is null)
        {
            ride.CancelledAt = time.GetUtcNow();
            ride.UpdatedAt = ride.CancelledAt.Value;
            await CalendarQueries.NotifyAsync(db, time, ride, NotificationTypes.ClubRideCancelled, userId, everyone: false, ct);
            await db.SaveChangesAsync(ct);
        }

        await Send.OkAsync(await CalendarQueries.DetailAsync(db, ride, userId, membership.Role, ct), ct);
    }
}
