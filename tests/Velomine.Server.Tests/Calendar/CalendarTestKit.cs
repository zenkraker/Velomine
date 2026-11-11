using System.Net.Http.Json;
using Velomine.Server.Features.Clubs;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Calendar;

/// <summary>Clubs, routes and planned rides for the calendar tests; the world is the route library's.</summary>
public static class CalendarTestKit
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static Task<TestApi> StartAsync(PostgresFixture postgres) =>
        Velomine.Server.Tests.Routes.RoutesTestKit.StartAsync(postgres);

    public static PlanClubRideRequest Request(
        string title = "Sunday ride",
        Guid? routeId = null,
        DateTimeOffset? startsAt = null,
        int? maxRiders = null,
        string meetingName = "Fountain, Piazza Garibaldi",
        string pace = RidePaces.Steady,
        bool noDrop = true,
        string? notes = "Steady pace, coffee at the lake") => new()
        {
            Title = title,
            StartsAt = startsAt ?? DateTimeOffset.UtcNow.AddDays(3),
            UtcOffsetMinutes = 60,
            MeetingName = meetingName,
            Latitude = 46.0,
            Longitude = 11.0,
            RouteId = routeId,
            Pace = pace,
            NoDrop = noDrop,
            Notes = notes,
            MaxRiders = maxRiders,
        };

    public static async Task<ClubRideDetailResponse> PlanAsync(HttpClient client, PlanClubRideRequest? request = null)
    {
        var response = await client.PostAsJsonAsync("/api/v1/club/rides", request ?? Request(), Ct);
        Assert.Equal(System.Net.HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<ClubRideDetailResponse>(Ct))!;
    }

    public static Task<ClubRideDetailResponse?> RideAsync(HttpClient client, Guid id) =>
        client.GetFromJsonAsync<ClubRideDetailResponse>($"/api/v1/club/rides/{id}", Ct);

    /// <summary>The same details as an edit request; a test changes one field at a time.</summary>
    public static UpdateClubRideRequest Edit(Guid id, PlanClubRideRequest request) => new()
    {
        Id = id,
        Title = request.Title,
        StartsAt = request.StartsAt,
        UtcOffsetMinutes = request.UtcOffsetMinutes,
        MeetingName = request.MeetingName,
        Latitude = request.Latitude,
        Longitude = request.Longitude,
        RouteId = request.RouteId,
        Pace = request.Pace,
        NoDrop = request.NoDrop,
        Notes = request.Notes,
        MaxRiders = request.MaxRiders,
    };

    public static Task<ClubRideListResponse?> RidesAsync(HttpClient client) =>
        client.GetFromJsonAsync<ClubRideListResponse>("/api/v1/club/rides", Ct);
}
