using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Supporter;

/// <summary>A rider's supporter licence. <c>Hidden</c> means the badge is not shown.</summary>
public sealed record RiderLicenceResponse(string Holder, int Serial, DateTimeOffset ActivatedAt, bool Hidden);

/// <summary>A club's supporter licence, the same to every member of that club.</summary>
public sealed record ClubSupporterResponse(Guid ClubId, string ClubName, string Holder, int Serial, DateTimeOffset ActivatedAt, bool Hidden);

/// <summary>
/// The caller's supporter status, for a badge in the app. <c>Available</c> is false on a server with no issuer key,
/// where the feature is off. The club licence is null unless the caller is in a club that has one.
/// </summary>
public sealed record SupporterStatusResponse(
    bool Available,
    RiderLicenceResponse? Rider,
    ClubSupporterResponse? Club);

public static class SupporterQueries
{
    public static async Task<SupporterStatusResponse> StatusAsync(
        VelomineDbContext db,
        bool available,
        Guid userId,
        CancellationToken ct)
    {
        var rider = await db.SupporterLicences.AsNoTracking()
            .Where(l => l.UserId == userId)
            .Select(l => new RiderLicenceResponse(l.Holder, l.Serial, l.ActivatedAt, l.Hidden))
            .FirstOrDefaultAsync(ct);

        var club = await (
                from l in db.SupporterLicences.AsNoTracking()
                join m in db.ClubMemberships.AsNoTracking() on l.ClubId equals m.ClubId
                where m.UserId == userId
                select new ClubSupporterResponse(m.ClubId, m.Club.Name, l.Holder, l.Serial, l.ActivatedAt, l.Hidden))
            .FirstOrDefaultAsync(ct);

        return new SupporterStatusResponse(available, rider, club);
    }
}
