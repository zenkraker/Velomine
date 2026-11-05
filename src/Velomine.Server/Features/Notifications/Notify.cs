using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Notifications;

/// <summary>
/// Adds notifications to the context. The caller saves them in the same SaveChanges as the change they are about,
/// so a notification never exists without its reason, or the other way round.
/// </summary>
public static class Notify
{
    public static void Add(VelomineDbContext db, TimeProvider time, Guid userId, string type, string subject,
        Guid? rideId = null, Guid? bikeId = null, Guid? componentId = null, Guid? aboutUserId = null) =>
        db.Notifications.Add(new Notification
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Type = type,
            Subject = subject.Length > 300 ? subject[..300] : subject,
            RideId = rideId,
            BikeId = bikeId,
            ComponentId = componentId,
            AboutUserId = aboutUserId,
            CreatedAt = time.GetUtcNow(),
        });

    /// <summary>Tells the member how their upload went.</summary>
    public static void RideRead(VelomineDbContext db, TimeProvider time, Ride ride)
    {
        var type = ride.Status switch
        {
            RideStatus.Ready => NotificationTypes.RideReady,
            RideStatus.Failed => NotificationTypes.RideFailed,
            RideStatus.Duplicate => NotificationTypes.RideDuplicate,
            _ => null,
        };
        if (type is not null) Add(db, time, ride.UserId, type, ride.FileName, rideId: ride.Id);
    }

    /// <summary>Tells every admin that a new account waits for approval.</summary>
    public static async Task SignUpWaitingAsync(VelomineDbContext db, UserManager<User> users, TimeProvider time, User newUser)
    {
        if (newUser.IsApproved) return;
        foreach (var admin in await users.GetUsersInRoleAsync(Accounts.Roles.Admin))
            Add(db, time, admin.Id, NotificationTypes.SignUpWaiting, $"{newUser.DisplayName} ({newUser.Email})", aboutUserId: newUser.Id);
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Warns about parts on these bikes that are nearly or fully worn. A part is warned about once per level:
    /// the notifications already sent are the record of that, so nothing else is stored.
    /// </summary>
    public static async Task WornPartsAsync(VelomineDbContext db, TimeProvider time, Guid userId, IReadOnlyCollection<Guid> bikeIds, CancellationToken ct)
    {
        if (bikeIds.Count == 0) return;
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var bikes = await db.Bikes.AsNoTracking().Include(b => b.Components)
            .Where(b => bikeIds.Contains(b.Id) && b.UserId == userId).ToListAsync(ct);

        foreach (var bike in bikes)
        {
            var due = BikeQueries.Wear(bike, await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct), clock.Today)
                .Where(x => x.Wear.Status is "soon" or "worn")
                .ToList();
            if (due.Count == 0) continue;

            var partIds = due.Select(x => x.Component.Id).ToList();
            var sent = await db.Notifications.AsNoTracking()
                .Where(n => n.ComponentId != null && partIds.Contains(n.ComponentId.Value))
                .Select(n => new { n.ComponentId, n.Type })
                .ToListAsync(ct);

            foreach (var (part, wear) in due)
            {
                var type = wear.Status == "worn" ? NotificationTypes.PartWorn : NotificationTypes.PartSoon;
                if (sent.Any(s => s.ComponentId == part.Id && (s.Type == type || s.Type == NotificationTypes.PartWorn))) continue;
                Add(db, time, userId, type, $"{ComponentTypes.NameOf(part.Type)} on {bike.Name}", bikeId: bike.Id, componentId: part.Id);
            }
        }

        await db.SaveChangesAsync(ct);
    }
}
