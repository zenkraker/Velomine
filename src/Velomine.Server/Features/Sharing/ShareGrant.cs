namespace Velomine.Server.Features.Sharing;

/// <summary>What a rider can share with their club. Routes is separate: numbers and charts need not reveal where.</summary>
public static class DataTypes
{
    public const string Rides = "rides";
    public const string Analytics = "analytics";
    public const string Routes = "routes";
    public const string Wellbeing = "wellbeing";

    public static readonly string[] All = [Rides, Analytics, Routes, Wellbeing];
}

/// <summary>Who may look: nobody (no row) or the club's coaches. A whole-club audience is reserved for a member view.</summary>
public static class Audiences
{
    public const string Coaches = "coaches";
    public const string Club = "club";

    /// <summary>The audiences a member can pick today. Whole-club reading needs a member-facing club view first.</summary>
    public static readonly string[] Assignable = [Coaches];
}

public static class ViewKinds
{
    public const string Summary = "summary";
    public const string Training = "training";
    public const string Ride = "ride";
    public const string Rides = "rides";
    public const string Route = "route";
    public const string PowerCurve = "power-curve";
    public const string Wellbeing = "wellbeing";
}

/// <summary>One rider's choice for one kind of data, in the club they belong to.</summary>
public sealed class ShareGrant
{
    public Guid Id { get; set; }

    public Guid MemberId { get; set; }

    public Guid ClubId { get; set; }

    public string DataType { get; set; } = DataTypes.Rides;

    public string Audience { get; set; } = Audiences.Coaches;

    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>One non-owner look at a member's data, kept so the member can see who looked and at what.</summary>
public sealed class ShareView
{
    public Guid Id { get; set; }

    public Guid MemberId { get; set; }

    public Guid ClubId { get; set; }

    public Guid ViewerId { get; set; }

    /// <summary>Kept as it was at the time, so the log still reads well after a rename or a deleted account.</summary>
    public string ViewerName { get; set; } = "";

    /// <summary>summary, training, ride, rides or route.</summary>
    public string What { get; set; } = "summary";

    public DateTimeOffset At { get; set; }
}
