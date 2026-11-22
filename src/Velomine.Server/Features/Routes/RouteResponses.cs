using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Routes;

/// <summary>
/// A route in a list. OwnerName is the member who added it, shown inside the club only. Latitude and Longitude are
/// the line thinned to a preview, so every card draws it on the map.
/// </summary>
public sealed record RouteSummaryResponse(
    Guid Id,
    string Name,
    string? Description,
    string Surface,
    double DistanceM,
    double? ClimbingM,
    Guid OwnerId,
    string OwnerName,
    DateTimeOffset CreatedAt,
    bool IsMine,
    bool IsShared,
    double[] Latitude,
    double[] Longitude);

/// <summary>A route as the database has it, its line whole: the list thins it to <see cref="RouteSummaryResponse"/>.</summary>
public sealed record RouteSummaryRow(
    Guid Id,
    string Name,
    string? Description,
    string Surface,
    double DistanceM,
    double? ClimbingM,
    Guid OwnerId,
    string OwnerName,
    DateTimeOffset CreatedAt,
    bool IsMine,
    bool IsShared,
    double[] Latitude,
    double[] Longitude)
{
    public RouteSummaryResponse ToResponse()
    {
        var (latitude, longitude) = RouteGeometry.Preview(Latitude, Longitude);
        return new RouteSummaryResponse(
            Id, Name, Description, Surface, DistanceM, ClimbingM, OwnerId, OwnerName, CreatedAt, IsMine, IsShared,
            latitude, longitude);
    }
}

/// <summary>A route with its line: latitude and longitude of every point, and elevation in metres when the route has it.</summary>
public sealed record RouteDetailResponse(
    Guid Id,
    string Name,
    string? Description,
    string Surface,
    double DistanceM,
    double? ClimbingM,
    Guid OwnerId,
    string OwnerName,
    DateTimeOffset CreatedAt,
    bool IsMine,
    bool IsShared,
    double[] Latitude,
    double[] Longitude,
    double[]? Elevation);

public sealed record RouteListResponse(RouteSummaryResponse[] Routes);

/// <summary>
/// The line a member is about to share, as it will be stored: positions already thinned and, for a ride, already
/// redacted by the member's privacy rules. Nothing is saved until the member confirms with a create request.
/// </summary>
public sealed record RouteDraftResponse(
    string? Name,
    double[] Latitude,
    double[] Longitude,
    double[]? Elevation,
    double DistanceM,
    double? ClimbingM);

/// <summary>An address, on this server, that downloads one route as GPX. It works for two minutes.</summary>
public sealed record RouteDownloadLinkResponse(string Path, DateTimeOffset ExpiresAt);

public static class RouteQueries
{
    /// <summary>The club the member belongs to, or null when they have none.</summary>
    public static Task<Guid?> ClubIdAsync(VelomineDbContext db, Guid userId, CancellationToken ct) =>
        db.ClubMemberships.AsNoTracking()
            .Where(m => m.UserId == userId)
            .Select(m => (Guid?)m.ClubId)
            .FirstOrDefaultAsync(ct);

    /// <summary>
    /// The routes this member may open: their own, and everything in their club's library. A member of another club,
    /// or of none, matches only their own.
    /// </summary>
    public static IQueryable<CyclingRoute> Visible(VelomineDbContext db, Guid userId, Guid? clubId) =>
        db.Routes.Where(r => r.UserId == userId || (clubId != null && r.ClubId == clubId));

    public static IQueryable<RouteSummaryRow> Summaries(IQueryable<CyclingRoute> routes, Guid viewerId) =>
        routes.Select(r => new RouteSummaryRow(
            r.Id,
            r.Name,
            r.Description,
            r.Surface,
            r.DistanceM,
            r.ClimbingM,
            r.UserId,
            r.Owner.DisplayName,
            r.CreatedAt,
            r.UserId == viewerId,
            r.ClubId != null,
            r.Line!.Latitude,
            r.Line.Longitude));

    public static RouteDetailResponse Detail(CyclingRoute route, Guid viewerId) => new(
        route.Id,
        route.Name,
        route.Description,
        route.Surface,
        route.DistanceM,
        route.ClimbingM,
        route.UserId,
        route.Owner.DisplayName,
        route.CreatedAt,
        route.UserId == viewerId,
        route.ClubId != null,
        route.Line!.Latitude,
        route.Line.Longitude,
        route.Line.Elevation is { } elevation ? [.. elevation.Select(e => (double)e)] : null);

    /// <summary>
    /// A draft of <paramref name="points"/>. A ride is measured at full resolution; a file is measured as it will be
    /// stored, because the member sends that line back and the server measures what it receives.
    /// </summary>
    public static RouteDraftResponse Draft(string? name, IReadOnlyList<RoutePoint> points, bool measureStored = false)
    {
        var simplified = RouteGeometry.Simplify(points);
        var (distance, climbing) = RouteGeometry.Measure(measureStored ? simplified : points);
        return DraftOf(name, simplified, distance, climbing);
    }

    public static RouteDraftResponse DraftOf(string? name, IReadOnlyList<RoutePoint> stored, double distanceM, double? climbingM) => new(
        name is { Length: > 120 } ? name[..120] : name,
        [.. stored.Select(p => p.Latitude)],
        [.. stored.Select(p => p.Longitude)],
        RouteGeometry.FilledElevation(stored) is { } elevation ? [.. elevation.Select(e => (double)e)] : null,
        distanceM,
        climbingM);
}
