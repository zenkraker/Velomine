using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

/// <summary>
/// A line on the map with a name: nothing about when, how fast or how anyone rode it. It belongs to the member who
/// added it. While <see cref="ClubId"/> is set it is also in that club's library; withdrawing, leaving the club or the
/// club going away clears it, and the route stays with its owner.
/// </summary>
public sealed class CyclingRoute
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public User Owner { get; set; } = null!;

    /// <summary>The club whose members can see it; null while it is not shared.</summary>
    public Guid? ClubId { get; set; }

    public string Name { get; set; } = "";

    public string? Description { get; set; }

    public string Surface { get; set; } = RouteSurfaces.Road;

    /// <summary>Measured along the line before it was thinned for storage.</summary>
    public double DistanceM { get; set; }

    /// <summary>Total climbing by the same method as a recorded ride; null when the line has no elevation.</summary>
    public double? ClimbingM { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public RouteLine? Line { get; set; }
}

/// <summary>The geometry, one row per route with one array per signal, aligned by index. Elevation is all points or none.</summary>
public sealed class RouteLine
{
    public Guid RouteId { get; set; }

    public double[] Latitude { get; set; } = [];

    public double[] Longitude { get; set; } = [];

    public float[]? Elevation { get; set; }
}

public static class RouteSurfaces
{
    public const string Road = "road";
    public const string Gravel = "gravel";
    public const string Mountain = "mountain";
    public const string Mixed = "mixed";

    public static readonly string[] All = [Road, Gravel, Mountain, Mixed];
}
