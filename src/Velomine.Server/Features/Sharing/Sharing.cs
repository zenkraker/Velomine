using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Clubs;

namespace Velomine.Server.Features.Sharing;

/// <summary>The one place that answers "may this person see that member's data?" Nothing else checks grants itself.</summary>
public static class SharingRules
{
    /// <summary>The caller is the owner or a coach of this club.</summary>
    public static async Task<bool> IsCoachAsync(VelomineDbContext db, Guid clubId, Guid userId, CancellationToken ct)
    {
        var membership = await db.ClubMemberships.AsNoTracking()
            .FirstOrDefaultAsync(m => m.ClubId == clubId && m.UserId == userId, ct);
        return membership is not null && membership.Role is ClubRoles.Owner or ClubRoles.Coach;
    }

    /// <summary>
    /// A club member may see [ownerId]'s [dataType] when the owner is in the same club and has shared that kind of
    /// data with an audience that includes the caller: the coaches (owner and coaches) or, later, the whole club.
    /// Anything else is a no: the endpoint then answers 404, like a missing record.
    /// </summary>
    public static async Task<bool> CanViewAsync(
        VelomineDbContext db,
        Guid clubId,
        Guid viewerId,
        Guid ownerId,
        string dataType,
        CancellationToken ct)
    {
        var viewer = await db.ClubMemberships.AsNoTracking()
            .FirstOrDefaultAsync(m => m.ClubId == clubId && m.UserId == viewerId, ct);
        if (viewer is null || viewerId == ownerId) return false;
        if (!await db.ClubMemberships.AsNoTracking().AnyAsync(m => m.ClubId == clubId && m.UserId == ownerId, ct))
            return false;

        var grant = await db.ShareGrants.AsNoTracking()
            .FirstOrDefaultAsync(g => g.ClubId == clubId && g.MemberId == ownerId && g.DataType == dataType, ct);
        if (grant is null) return false;

        return grant.Audience switch
        {
            Audiences.Club => true,
            Audiences.Coaches => viewer.Role is ClubRoles.Owner or ClubRoles.Coach,
            _ => false,
        };
    }

    /// <summary>Remembers that someone other than the owner looked. The name is kept, so a later rename does not rewrite history.</summary>
    public static Task RecordViewAsync(
        VelomineDbContext db,
        TimeProvider time,
        Guid memberId,
        Guid clubId,
        Guid viewerId,
        string viewerName,
        string what,
        CancellationToken ct,
        Guid? rideId = null) =>
        RecordViewsAsync(db, time, [memberId], clubId, viewerId, viewerName, what, ct, rideId);

    /// <summary>The same, for a roster that shows several athletes at once: one round trip, one timestamp.</summary>
    public static async Task RecordViewsAsync(
        VelomineDbContext db,
        TimeProvider time,
        IEnumerable<Guid> memberIds,
        Guid clubId,
        Guid viewerId,
        string viewerName,
        string what,
        CancellationToken ct,
        Guid? rideId = null)
    {
        var at = time.GetUtcNow();
        var added = false;
        foreach (var memberId in memberIds)
        {
            db.ShareViews.Add(new ShareView
            {
                Id = Guid.NewGuid(),
                MemberId = memberId,
                ClubId = clubId,
                ViewerId = viewerId,
                ViewerName = viewerName,
                What = what,
                RideId = rideId,
                At = at,
            });
            added = true;
        }
        if (added) await db.SaveChangesAsync(ct);
    }
}
