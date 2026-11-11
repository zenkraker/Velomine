using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

/// <summary>
/// "I'm in", until the ride starts. A full ride, a cancelled ride and a ride already under way each say why. The ride
/// row is locked while the places are counted, so two riders clicking at once never take the last place twice.
/// </summary>
public sealed class JoinClubRide(VelomineDbContext db, TimeProvider time)
    : Endpoint<ClubRideIdRequest, ClubRideDetailResponse>
{
    public override void Configure()
    {
        Post("club/rides/{id}/participation");
        Description(d => d.Produces<ClubRideDetailResponse>(200).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(ClubRideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
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

        if (ride.CancelledAt is not null)
        {
            AddError("This ride is cancelled.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        if (ride.StartsAt <= time.GetUtcNow())
        {
            AddError("This ride has already started.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        if (ride.SignUps.All(s => s.UserId != userId))
        {
            await using var transaction = await db.Database.BeginTransactionAsync(ct);
            await db.Database.ExecuteSqlAsync(
                $"SELECT 1 FROM calendar.planned_rides WHERE id = {ride.Id} FOR UPDATE", ct);
            // The same rider may have clicked twice: the first request is already committed when this one has the lock.
            var alreadyIn = await db.RideSignUps.AnyAsync(
                s => s.PlannedRideId == ride.Id && s.UserId == userId, ct);
            if (!alreadyIn)
            {
                var taken = await db.RideSignUps.CountAsync(s => s.PlannedRideId == ride.Id, ct);
                if (ride.MaxRiders is { } max && taken >= max)
                {
                    AddError("This ride is full.");
                    await Send.ErrorsAsync(409, ct);
                    return;
                }

                db.RideSignUps.Add(new RideSignUp
                {
                    PlannedRideId = ride.Id,
                    UserId = userId,
                    CreatedAt = time.GetUtcNow(),
                });
                await db.SaveChangesAsync(ct);
            }

            await transaction.CommitAsync(ct);
            await db.Entry(ride).Collection(r => r.SignUps).LoadAsync(ct);
        }

        await Send.OkAsync(await CalendarQueries.DetailAsync(db, ride, userId, membership.Role, ct), ct);
    }
}

/// <summary>Takes "I'm in" back, until the ride starts. A ride already cancelled still lets a rider out.</summary>
public sealed class LeaveClubRide(VelomineDbContext db, TimeProvider time) : Endpoint<ClubRideIdRequest>
{
    public override void Configure()
    {
        Delete("club/rides/{id}/participation");
        Description(d => d.Produces(204).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(ClubRideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
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

        if (ride.CancelledAt is null && ride.StartsAt <= time.GetUtcNow())
        {
            AddError("This ride has already started.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        if (ride.SignUps.FirstOrDefault(s => s.UserId == userId) is { } signUp)
        {
            db.RideSignUps.Remove(signUp);
            await db.SaveChangesAsync(ct);
        }

        await Send.NoContentAsync(ct);
    }
}
