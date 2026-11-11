using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

/// <summary>A planned ride as a list shows it. EndsAt is a guess from the route and the pace; nothing stores it.</summary>
public sealed record ClubRideSummaryResponse(
    Guid Id,
    string Title,
    DateTimeOffset StartsAt,
    DateTimeOffset EndsAt,
    int UtcOffsetMinutes,
    string MeetingName,
    string Pace,
    bool NoDrop,
    Guid? RouteId,
    string? RouteName,
    double? RouteDistanceM,
    int SignUpCount,
    int? MaxRiders,
    bool IsFull,
    bool IsSignedUp,
    bool IsCancelled,
    string? CreatedByName);

public sealed record ClubRideParticipantResponse(Guid UserId, string DisplayName);

public sealed record ClubRideDetailResponse(
    ClubRideSummaryResponse Ride,
    double MeetingLatitude,
    double MeetingLongitude,
    string? Notes,
    bool CanPlan,
    ClubRideParticipantResponse[] Participants);

/// <summary>The club's calendar: what is coming soonest first, and what has just happened newest first.</summary>
public sealed record ClubRideListResponse(ClubRideSummaryResponse[] Upcoming, ClubRideSummaryResponse[] Past);

/// <summary>Where the member's calendar subscribes. Only shown when a new address is made.</summary>
public sealed record CalendarFeedAddressResponse(string Url, DateTimeOffset CreatedAt);

/// <summary>Whether an address is active; the address itself is not stored in a readable form.</summary>
public sealed record CalendarFeedStatusResponse(bool Active, DateTimeOffset? CreatedAt);

/// <summary>The route of a ride, as far as the club library still has it.</summary>
public sealed record RideRouteRef(Guid Id, string Name, double DistanceM);

public static class CalendarQueries
{
    /// <summary>Admins and coaches plan the club's rides; everybody else rides them.</summary>
    public static bool CanPlan(string? role) => role is ClubRoles.Owner or ClubRoles.Coach;

    /// <summary>
    /// A planned start to the second. A calendar entry has no finer meaning, and a client that re-sends a time it got
    /// from the server must not look like a change just because PostgreSQL keeps microseconds and the JSON did not.
    /// </summary>
    public static DateTimeOffset WholeSeconds(DateTimeOffset instant) =>
        DateTimeOffset.FromUnixTimeSeconds(instant.ToUnixTimeSeconds());

    /// <summary>
    /// What the feed assumes a ride takes: its route's distance at the pace, at least half an hour and at most eight
    /// hours, or two hours when there is no route. It is a guess for a calendar block, nothing more.
    /// </summary>
    public static DateTimeOffset EndsAt(DateTimeOffset startsAt, string pace, double? routeDistanceM)
    {
        var hours = routeDistanceM is { } distance
            ? Math.Clamp(distance / 1000 / RidePaces.Kmh(pace), 0.5, 8)
            : 2;
        return startsAt.AddHours(hours);
    }

    /// <summary>Whether this is a route the club may plan with: in its library, shared by its owner.</summary>
    public static Task<bool> RouteInLibraryAsync(VelomineDbContext db, Guid clubId, Guid? routeId, CancellationToken ct) =>
        routeId is null ? Task.FromResult(true) : db.Routes.AnyAsync(r => r.Id == routeId && r.ClubId == clubId, ct);

    /// <summary>
    /// The routes of these rides that the club may still use, by id. A route withdrawn from the library stops being
    /// the ride's route, which is what "the ride stays and has no route" means.
    /// </summary>
    public static async Task<Dictionary<Guid, RideRouteRef>> SharedRoutesAsync(
        VelomineDbContext db, Guid clubId, IEnumerable<Guid?> routeIds, CancellationToken ct)
    {
        var ids = routeIds.OfType<Guid>().Distinct().ToArray();
        if (ids.Length == 0) return [];
        return await db.Routes.AsNoTracking()
            .Where(r => ids.Contains(r.Id) && r.ClubId == clubId)
            .Select(r => new RideRouteRef(r.Id, r.Name, r.DistanceM))
            .ToDictionaryAsync(r => r.Id, ct);
    }

    public static async Task<Dictionary<Guid, string>> PlannerNamesAsync(
        VelomineDbContext db, IEnumerable<Guid?> userIds, CancellationToken ct)
    {
        var ids = userIds.OfType<Guid>().Distinct().ToArray();
        if (ids.Length == 0) return [];
        return await db.Users.AsNoTracking()
            .Where(u => ids.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.DisplayName, ct);
    }

    public static ClubRideSummaryResponse Summary(
        PlannedRide ride,
        Guid viewerId,
        IReadOnlyDictionary<Guid, RideRouteRef> routes,
        IReadOnlyDictionary<Guid, string> planners)
    {
        var route = ride.RouteId is { } routeId && routes.TryGetValue(routeId, out var found) ? found : null;
        var signUps = ride.SignUps.Count;
        return new ClubRideSummaryResponse(
            ride.Id,
            ride.Title,
            ride.StartsAt,
            EndsAt(ride.StartsAt, ride.Pace, route?.DistanceM),
            ride.UtcOffsetMinutes,
            ride.MeetingName,
            ride.Pace,
            ride.NoDrop,
            route?.Id,
            route?.Name,
            route?.DistanceM,
            signUps,
            ride.MaxRiders,
            ride.MaxRiders is { } max && signUps >= max,
            ride.SignUps.Any(s => s.UserId == viewerId),
            ride.CancelledAt is not null,
            ride.CreatedByUserId is { } plannerId && planners.TryGetValue(plannerId, out var name) ? name : null);
    }

    /// <summary>The ride with its sign-ups and names, or null when it is not in the caller's club.</summary>
    public static async Task<PlannedRide?> RideAsync(VelomineDbContext db, Guid clubId, Guid rideId, CancellationToken ct) =>
        await db.PlannedRides
            .Include(r => r.SignUps)
            .FirstOrDefaultAsync(r => r.Id == rideId && r.ClubId == clubId, ct);

    /// <summary>One ride as the member sees it, with who else is in (names stay inside the club).</summary>
    public static async Task<ClubRideDetailResponse> DetailAsync(
        VelomineDbContext db, PlannedRide ride, Guid viewerId, string? role, CancellationToken ct)
    {
        var routes = await SharedRoutesAsync(db, ride.ClubId, [ride.RouteId], ct);
        var planners = await PlannerNamesAsync(db, [ride.CreatedByUserId], ct);
        var summary = Summary(ride, viewerId, routes, planners);
        var userIds = ride.SignUps.Select(s => s.UserId).ToArray();
        var names = await db.Users.AsNoTracking().Where(u => userIds.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.DisplayName, ct);
        var participants = ride.SignUps
            .OrderBy(s => s.CreatedAt).ThenBy(s => s.UserId)
            .Select(s => new ClubRideParticipantResponse(s.UserId, names.GetValueOrDefault(s.UserId, "")))
            .ToArray();

        return new ClubRideDetailResponse(
            summary,
            ride.MeetingLatitude,
            ride.MeetingLongitude,
            ride.Notes,
            CanPlan(role),
            participants);
    }

    /// <summary>Tells the members who are in, or everyone, about one event: a new ride, a change or a cancellation.</summary>
    public static async Task NotifyAsync(
        VelomineDbContext db,
        TimeProvider time,
        PlannedRide ride,
        string type,
        Guid? exceptUserId,
        bool everyone,
        CancellationToken ct)
    {
        var users = everyone
            ? await db.ClubMemberships.AsNoTracking()
                .Where(m => m.ClubId == ride.ClubId && m.UserId != exceptUserId)
                .Select(m => m.UserId).ToListAsync(ct)
            : ride.SignUps.Where(s => s.UserId != exceptUserId).Select(s => s.UserId).ToList();
        if (users.Count == 0) return;

        // A ride with the same title and start repeats nothing in the subject, so the notification stays short.
        foreach (var userId in users)
            Notify.Add(db, time, userId, type, ride.Title, plannedRideId: ride.Id);
    }
}
