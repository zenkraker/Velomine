using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Accounts;

public enum AccountDeletionResult
{
    Deleted,
    NotFound,
    /// <summary>The account owns the only owner membership of a club; deleting it would leave the club unmanageable.</summary>
    SoleClubOwner,
}
/// <summary>
/// Deletes an account and everything the member owns. The database does the cascade (rides and their samples, bikes and
/// parts, goals, notifications, sign-ins); this also removes the original ride files that nothing else uses, so no
/// member data is left on disk. Used when an admin deletes an account and when a member deletes their own.
/// </summary>
public sealed class AccountDeletion(VelomineDbContext db, UserManager<User> users, RideFileStore files)
{
    /// <summary>False when there is no such account.</summary>
    public async Task<AccountDeletionResult> DeleteAsync(Guid userId, CancellationToken ct)
    {
        if (await users.FindByIdAsync(userId.ToString()) is not { } user) return AccountDeletionResult.NotFound;

        var ownedClub = await db.ClubMemberships.AsNoTracking()
            .Where(m => m.UserId == userId && m.Role == ClubRoles.Owner)
            .Select(m => (Guid?)m.ClubId)
            .FirstOrDefaultAsync(ct);
        if (ownedClub is { } clubId &&
            !await db.ClubMemberships.AnyAsync(m => m.ClubId == clubId && m.UserId != userId && m.Role == ClubRoles.Owner, ct))
            return AccountDeletionResult.SoleClubOwner;

        var hashes = await db.Rides.Where(r => r.UserId == userId).Select(r => r.FileSha256).Distinct().ToListAsync(ct);

        var result = await users.DeleteAsync(user);
        if (!result.Succeeded)
            throw new InvalidOperationException("Could not delete the account: " + string.Join("; ", result.Errors.Select(e => e.Description)));

        // Files are named by their hash, so two members who uploaded the same file share it: keep it while a ride still uses it.
        foreach (var sha in hashes)
            if (!await db.Rides.AnyAsync(r => r.FileSha256 == sha, ct)) files.Delete(sha);
        return AccountDeletionResult.Deleted;
    }
}
