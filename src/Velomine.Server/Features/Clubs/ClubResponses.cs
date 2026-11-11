using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Clubs;

public sealed record ClubMemberResponse(Guid UserId, string DisplayName, string Role, DateTimeOffset JoinedAt);

/// <summary>
/// The club's plan, for its owner only. <c>Blocked</c> is "full" or "ended" when the club cannot admit another member,
/// otherwise null. The server holds no prices.
/// </summary>
public sealed record ClubPlanResponse(int MemberCount, int? MemberLimit, DateOnly? PaidUntil, string? Blocked);

/// <summary>A club as its members see it. The join code and the plan are only for the owner.</summary>
public sealed record ClubResponse(
    Guid Id,
    string Name,
    bool IsActive,
    string MyRole,
    string? JoinCode,
    double? Latitude,
    double? Longitude,
    bool IsDiscoverable,
    ClubMemberResponse[] Members,
    ClubPlanResponse? Plan);

/// <summary>
/// Null club when the signed-in account is not in a club yet. <c>CanStartClub</c> is true only for such a rider on a
/// server where the operator lets riders start clubs.
/// </summary>
public sealed record MyClubResponse(ClubResponse? Club, bool CanStartClub);

/// <summary>A club as the instance admin sees it.</summary>
public sealed record AdminClubResponse(
    Guid Id,
    string Name,
    string JoinCode,
    bool IsActive,
    double? Latitude,
    double? Longitude,
    bool IsDiscoverable,
    DateTimeOffset CreatedAt,
    int MemberCount,
    int? MemberLimit,
    DateOnly? PaidUntil,
    Guid? OwnerId,
    string? OwnerName,
    string? OwnerEmail,
    string? OwnerRole,
    ClubMemberResponse[] Members);

public sealed record AdminClubListResponse(AdminClubResponse[] Clubs);

public sealed record JoinCodeResponse(string JoinCode);

public static class ClubQueries
{
    public static async Task<ClubResponse?> MyClubAsync(VelomineDbContext db, TimeProvider time, Guid userId, CancellationToken ct)
    {
        var membership = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.Club)
            .FirstOrDefaultAsync(m => m.UserId == userId, ct);
        return membership is null ? null : await DetailAsync(db, time, membership.Club, membership.Role, ct);
    }

    public static async Task<ClubResponse> DetailAsync(
        VelomineDbContext db,
        TimeProvider time,
        Club club,
        string myRole,
        CancellationToken ct)
    {
        var members = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.User)
            .Where(m => m.ClubId == club.Id)
            .ToListAsync(ct);

        var roster = members
            .OrderBy(m => RoleRank(m.Role))
            .ThenBy(m => m.User.DisplayName, StringComparer.OrdinalIgnoreCase)
            .Select(m => new ClubMemberResponse(m.UserId, m.User.DisplayName, m.Role, m.JoinedAt))
            .ToArray();

        return new ClubResponse(
            club.Id,
            club.Name,
            club.IsActive,
            myRole,
            myRole == ClubRoles.Owner ? club.JoinCode : null,
            club.Latitude,
            club.Longitude,
            club.IsDiscoverable,
            roster,
            myRole == ClubRoles.Owner && (club.MemberLimit is not null || club.PaidUntil is not null)
                ? new ClubPlanResponse(
                    roster.Length,
                    club.MemberLimit,
                    club.PaidUntil,
                    ClubPlan.BlockedReason(club.MemberLimit, club.PaidUntil, roster.Length, ClubPlan.Today(time)))
                : null);
    }

    public static async Task<AdminClubResponse> AdminAsync(VelomineDbContext db, Club club, CancellationToken ct)
    {
        var members = await db.ClubMemberships.AsNoTracking()
            .Include(m => m.User)
            .Where(m => m.ClubId == club.Id)
            .ToListAsync(ct);
        var owner = members.FirstOrDefault(m => m.Role == ClubRoles.Owner);
        var roster = members
            .OrderBy(m => RoleRank(m.Role))
            .ThenBy(m => m.User.DisplayName, StringComparer.OrdinalIgnoreCase)
            .Select(m => new ClubMemberResponse(m.UserId, m.User.DisplayName, m.Role, m.JoinedAt))
            .ToArray();

        return new AdminClubResponse(
            club.Id,
            club.Name,
            club.JoinCode,
            club.IsActive,
            club.Latitude,
            club.Longitude,
            club.IsDiscoverable,
            club.CreatedAt,
            members.Count,
            club.MemberLimit,
            club.PaidUntil,
            owner?.UserId,
            owner?.User.DisplayName,
            owner?.User.Email,
            owner?.Role,
            roster);
    }

    private static int RoleRank(string role) => role switch
    {
        ClubRoles.Owner => 0,
        ClubRoles.Coach => 1,
        _ => 2,
    };
}
