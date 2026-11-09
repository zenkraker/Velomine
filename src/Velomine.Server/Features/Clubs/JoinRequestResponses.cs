using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Clubs;

/// <summary>The rider's own pending request, with the club it is for.</summary>
public sealed record PendingJoinRequestResponse(
    Guid Id,
    Guid ClubId,
    string ClubName,
    string? Note,
    DateTimeOffset CreatedAt);

public sealed record MyJoinRequestResponse(PendingJoinRequestResponse? Request);

/// <summary>One pending request as the club's owner sees it.</summary>
public sealed record JoinRequestResponse(
    Guid Id,
    Guid UserId,
    string DisplayName,
    string? Note,
    DateTimeOffset CreatedAt);

public sealed record JoinRequestsResponse(JoinRequestResponse[] Requests);

public static class JoinRequestQueries
{
    /// <summary>The one request a rider may have open, or null.</summary>
    public static Task<PendingJoinRequestResponse?> MineAsync(VelomineDbContext db, Guid userId, CancellationToken ct) =>
        db.ClubJoinRequests.AsNoTracking()
            .Where(r => r.UserId == userId)
            .Select(r => new PendingJoinRequestResponse(r.Id, r.ClubId, r.Club.Name, r.Note, r.CreatedAt))
            .FirstOrDefaultAsync(ct);
}
