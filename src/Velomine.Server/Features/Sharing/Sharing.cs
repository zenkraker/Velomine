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
    /// A coach (or the owner) of [clubId] may see [ownerId]'s [dataType] when the owner is in the same club and has
    /// shared that kind of data. Anything else is a no: the endpoint then answers 404, like a missing record.
    /// </summary>
    public static async Task<bool> CanViewAsync(
        VelomineDbContext db,
        Guid clubId,
        Guid viewerId,
        Guid ownerId,
        string dataType,
        CancellationToken ct)
    {
        if (!await IsCoachAsync(db, clubId, viewerId, ct)) return false;
        if (!await db.ClubMemberships.AsNoTracking().AnyAsync(m => m.ClubId == clubId && m.UserId == ownerId, ct))
            return false;
        return await db.ShareGrants.AsNoTracking()
            .AnyAsync(g => g.ClubId == clubId && g.MemberId == ownerId && g.DataType == dataType, ct);
    }

    /// <summary>Remembers that someone other than the owner looked. The name is kept, so a later rename does not rewrite history.</summary>
    public static async Task RecordViewAsync(
        VelomineDbContext db,
        TimeProvider time,
        Guid memberId,
        Guid clubId,
        Guid viewerId,
        string viewerName,
        string what,
        CancellationToken ct)
    {
        db.ShareViews.Add(new ShareView
        {
            Id = Guid.NewGuid(),
            MemberId = memberId,
            ClubId = clubId,
            ViewerId = viewerId,
            ViewerName = viewerName,
            What = what,
            At = time.GetUtcNow(),
        });
        await db.SaveChangesAsync(ct);
    }
}
