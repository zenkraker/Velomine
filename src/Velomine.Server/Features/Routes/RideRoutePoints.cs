using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Routes;

public enum RideRouteProblem
{
    None,
    NotFound,
    NoMap,
    NothingLeft,
}

public sealed record RideRoute(RideRouteProblem Problem, string FileName, IReadOnlyList<RoutePoint> Points);

/// <summary>
/// The line of a member's own ride as their club may see it. It goes through the one privacy function with the route
/// switched on, exactly as a coach's view of the ride would: privacy zones and start and end trimming remove their
/// points, and elevation is dropped when the member hides it. Only position and elevation are copied. A hidden stretch
/// in the middle is bridged by the line, which reveals no more than that the road passed through.
/// </summary>
public static class RideRoutePoints
{
    public static async Task<RideRoute> LoadAsync(VelomineDbContext db, Guid userId, Guid rideId, CancellationToken ct)
    {
        var ride = await db.Rides.AsNoTracking()
            .Where(r => r.Id == rideId && r.UserId == userId)
            .FirstOrDefaultAsync(ct);
        if (ride is null) return new RideRoute(RideRouteProblem.NotFound, "", []);

        var streams = ride.Status == RideStatus.Ready
            ? await db.RideStreams.AsNoTracking().FirstOrDefaultAsync(s => s.RideId == rideId, ct)
            : null;
        if (streams?.Latitude is null || streams.Longitude is null)
            return new RideRoute(RideRouteProblem.NoMap, ride.FileName, []);

        var privacy = await PrivacyRules.LoadAsync(db, userId, ride, ct);
        var visible = PrivacyRules.ForViewer(
            new RideStreamsResponse(
                streams.Time, streams.Latitude, streams.Longitude, streams.Altitude,
                null, null, null, null, null, null),
            privacy,
            showRoute: true);

        var points = new List<RoutePoint>();
        for (var i = 0; i < visible.Time.Length; i++)
        {
            if (visible.Latitude?[i] is not { } latitude || visible.Longitude?[i] is not { } longitude) continue;
            if (!RouteGeometry.IsValid(latitude, longitude)) continue;
            points.Add(new RoutePoint(latitude, longitude, visible.Altitude?[i]));
        }

        return points.Count < 2 || RouteGeometry.Measure(points).DistanceM < RouteGeometry.MinDistanceM
            ? new RideRoute(RideRouteProblem.NothingLeft, ride.FileName, [])
            : new RideRoute(RideRouteProblem.None, ride.FileName, points);
    }

    public static string Message(RideRouteProblem problem) => problem switch
    {
        RideRouteProblem.NoMap => "This ride has no map: it is still being read, or it was recorded without GPS.",
        _ => "Nothing is left of this ride to share once your privacy settings are applied.",
    };
}
