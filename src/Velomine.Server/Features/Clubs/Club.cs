namespace Velomine.Server.Features.Clubs;

/// <summary>A club on this server. One server can host several; a member belongs to exactly one.</summary>
public sealed class Club
{
    public Guid Id { get; set; }

    public string Name { get; set; } = "";

    /// <summary>What a person types (or follows in a link) to join. Rotating it revokes the old one.</summary>
    public string JoinCode { get; set; } = "";

    /// <summary>A disabled club keeps its members and data but takes no new joins.</summary>
    public bool IsActive { get; set; } = true;

    /// <summary>Where the club meets, when its owner set it. Both coordinates or neither.</summary>
    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    /// <summary>Whether riders without a club may find this club by distance and ask to join.</summary>
    public bool IsDiscoverable { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>The instance admin who created it. The day-to-day owner is the owner membership.</summary>
    public Guid CreatedBy { get; set; }

    public List<ClubMembership> Memberships { get; set; } = [];
}

/// <summary>One person's place in a club: its owner, a coach, or a rider.</summary>
public sealed class ClubMembership
{
    public Guid Id { get; set; }

    public Guid ClubId { get; set; }

    public Club Club { get; set; } = null!;

    public Guid UserId { get; set; }

    public Accounts.User User { get; set; } = null!;

    public string Role { get; set; } = ClubRoles.Member;

    public DateTimeOffset JoinedAt { get; set; }
}

public static class ClubRoles
{
    public const string Owner = "owner";
    public const string Coach = "coach";
    public const string Member = "member";

    public static readonly string[] All = [Owner, Coach, Member];

    /// <summary>What an owner may set on someone else. Ownership moves only with the instance admin.</summary>
    public static readonly string[] Assignable = [Coach, Member];
}
