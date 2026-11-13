using System.Globalization;
using System.Net.Http.Json;
using System.Text;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Routes;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Routes;

/// <summary>Members, clubs, rides and routes for the route library and calendar tests.</summary>
public static class RoutesTestKit
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static Task<TestApi> StartAsync(PostgresFixture postgres) =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    /// <summary>The member record every test shares; this kit only adds the club and route helpers around it.</summary>
    public static Task<TestMember> NewMemberAsync(TestApi api, string name = "Test Rider") => api.NewMemberAsync(name);

    public static async Task<AdminClubResponse> CreateClubAsync(TestApi api, TestMember owner)
    {
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = owner.Email },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    public static async Task JoinAsync(TestMember member, AdminClubResponse club) =>
        (await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();

    public static async Task<TestMember> NewClubMemberAsync(TestApi api, AdminClubResponse club, string name = "Club Rider")
    {
        var member = await NewMemberAsync(api, name);
        await JoinAsync(member, club);
        return member;
    }

    /// <summary>Two clubs, each with an owner, a coach and a rider, and one rider with no club.</summary>
    public sealed record World(
        AdminClubResponse Club,
        TestMember Owner,
        TestMember Coach,
        TestMember Rider,
        AdminClubResponse OtherClub,
        TestMember OtherOwner,
        TestMember OtherRider,
        TestMember Loner);

    public static async Task<World> NewWorldAsync(TestApi api)
    {
        var owner = await NewMemberAsync(api, "Olivia Owner");
        var club = await CreateClubAsync(api, owner);
        var coach = await NewClubMemberAsync(api, club, "Carlo Coach");
        (await owner.Client.PutAsJsonAsync(
            $"/api/v1/club/members/{coach.Id}/role", new SetClubMemberRoleRequest { Role = "coach" }, Ct)).EnsureSuccessStatusCode();
        var rider = await NewClubMemberAsync(api, club, "Rita Rider");

        var otherOwner = await NewMemberAsync(api, "Otto Other");
        var otherClub = await CreateClubAsync(api, otherOwner);
        var otherRider = await NewClubMemberAsync(api, otherClub, "Nora Neighbour");
        var loner = await NewMemberAsync(api, "Lena Loner");
        return new World(club, owner, coach, rider, otherClub, otherOwner, otherRider, loner);
    }

    public static async Task<Guid> UploadAndWaitAsync(HttpClient client, byte[] file) =>
        (await TestApi.UploadAndWaitAsync(client, file)).Id;

    /// <summary>A 10 minute ride that starts at 46.0, 11.0 and rides north at 8 m/s: about 4.8 km.</summary>
    public static Task<Guid> UploadRideAsync(HttpClient client) =>
        UploadAndWaitAsync(client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));

    public static async Task AddZoneAsync(HttpClient client, double latitude, double longitude, int radiusM) =>
        (await client.PostAsJsonAsync(
            "/api/v1/privacy/zones",
            new CreatePrivacyZoneRequest { Name = "Home", Latitude = latitude, Longitude = longitude, RadiusM = radiusM },
            Ct)).EnsureSuccessStatusCode();

    /// <summary>A straight line north from 46.0, 11.0 with a hill in the middle: about 1.1 km for 10 points.</summary>
    public static CreateRouteRequest LineRequest(string name = "Lake loop", string surface = "road", int points = 10) => new()
    {
        Name = name,
        Surface = surface,
        Latitude = [.. Enumerable.Range(0, points).Select(i => 46.0 + i * 0.001)],
        Longitude = [.. Enumerable.Range(0, points).Select(i => 11.0 + i * 0.0002)],
        Elevation = [.. Enumerable.Range(0, points).Select(i => 300.0 + 20 * Math.Sin(i * Math.PI / (points - 1)))],
    };

    public static async Task<RouteDetailResponse> CreateRouteAsync(HttpClient client, CreateRouteRequest? request = null)
    {
        var response = await client.PostAsJsonAsync("/api/v1/routes", request ?? LineRequest(), Ct);
        Assert.Equal(System.Net.HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<RouteDetailResponse>(Ct))!;
    }

    public static string Gpx(string name, int points = 6, bool elevation = true)
    {
        var builder = new StringBuilder("<?xml version=\"1.0\"?><gpx version=\"1.1\" creator=\"test\" xmlns=\"http://www.topografix.com/GPX/1/1\">");
        builder.Append(CultureInfo.InvariantCulture, $"<metadata><name>{name}</name></metadata><trk><trkseg>");
        for (var i = 0; i < points; i++)
        {
            builder.Append(CultureInfo.InvariantCulture, $"<trkpt lat=\"{46.0 + i * 0.001:0.000000}\" lon=\"{11.0 + i % 2 * 0.0005:0.000000}\">");
            if (elevation) builder.Append(CultureInfo.InvariantCulture, $"<ele>{300 + i * 5}</ele>");
            builder.Append("</trkpt>");
        }

        return builder.Append("</trkseg></trk></gpx>").ToString();
    }
}
