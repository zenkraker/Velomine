using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;
using Member = Velomine.Server.Tests.TestMember;

namespace Velomine.Server.Tests.Privacy;

[Collection("postgres")]
public sealed class PrivacyTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));


    private static Task<Member> NewMemberAsync(TestApi api) => api.NewMemberAsync();

    private static async Task<AdminClubResponse> CreateClubAsync(TestApi api, Member owner)
    {
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = owner.Email },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    private static async Task JoinAsync(Member member, AdminClubResponse club) =>
        (await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();

    private static Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file) => TestApi.UploadAndWaitAsync(client, file);

    [Fact]
    public async Task PrivacyZones_ShouldHideRoutePointsInsideTheZone_WhenCoachReadsStreams()
    {
        await using var api = await StartAsync();
        var (owner, club, rider, rideId) = await SharedRideAsync(api);
        var zone = await AddZoneAsync(rider.Client, 46.0, 11.0, 500);
        Assert.Equal(HttpStatusCode.Created, zone.StatusCode);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(streams!.Latitude![0]);
        Assert.Null(streams.Latitude[60]);  // 480 m from the start, inside the 500 m zone
        Assert.NotNull(streams.Latitude[63]); // 504 m, outside
        Assert.Equal(streams.Time.Length, streams.Latitude.Length);
    }

    [Fact]
    public async Task PrivacyZones_ShouldNotHideTheRoute_WhenTheOwnerReadsTheirOwnStreams()
    {
        await using var api = await StartAsync();
        var (_, _, rider, rideId) = await SharedRideAsync(api);
        await AddZoneAsync(rider.Client, 46.0, 11.0, 500);

        var streams = await rider.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{rideId}/streams", Ct);

        Assert.NotNull(streams!.Latitude![0]);
        Assert.NotNull(streams.Latitude[60]);
    }

    [Fact]
    public async Task HidePower_ShouldHidePowerAndItsNumbers_WhenCoachReadsTheRide()
    {
        await using var api = await StartAsync();
        var (owner, club, rider, rideId) = await SharedRideAsync(api);
        var settings = await rider.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest
            {
                HidePower = true,
                HideHeartRate = false,
                HideCadence = false,
                HideSpeed = false,
                HideElevation = false,
                HideTemperature = false,
                TrimStartM = 0,
                TrimEndM = 0,
            },
            Ct);
        settings.EnsureSuccessStatusCode();

        var ride = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);
        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(ride!.AvgPowerW);
        Assert.Null(ride.MaxPowerW);
        Assert.Null(ride.NormalizedPowerW);
        Assert.Null(streams!.Power);
        Assert.NotNull(streams.HeartRate);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/power-curve", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training", Ct)).StatusCode);
    }

    [Fact]
    public async Task HideHeartRate_ShouldHideHeartRate_WhenCoachReadsStreams()
    {
        await using var api = await StartAsync();
        var (owner, club, rider, rideId) = await SharedRideAsync(api);
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest
            {
                HideHeartRate = true,
                HidePower = false,
                HideCadence = false,
                HideSpeed = false,
                HideElevation = false,
                HideTemperature = false,
                TrimStartM = 0,
                TrimEndM = 0,
            },
            Ct)).EnsureSuccessStatusCode();

        var ride = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);
        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(ride!.AvgHeartRate);
        Assert.Null(streams!.HeartRate);
        Assert.NotNull(streams.Power);
    }

    [Fact]
    public async Task TrimStart_ShouldHideTheFirstMetres_WhenCoachReadsStreams()
    {
        await using var api = await StartAsync();
        var (owner, club, rider, rideId) = await SharedRideAsync(api);
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest
            {
                HideHeartRate = false,
                HidePower = false,
                HideCadence = false,
                HideSpeed = false,
                HideElevation = false,
                HideTemperature = false,
                TrimStartM = 500,
                TrimEndM = 0,
            },
            Ct)).EnsureSuccessStatusCode();

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(streams!.Latitude![0]);
        Assert.Null(streams.Latitude[60]);
        Assert.NotNull(streams.Latitude[63]);
    }

    [Fact]
    public async Task CreatePrivacyZone_ShouldRefuseARadiusOverOneMile_WhenAsked()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api);

        var response = await AddZoneAsync(rider.Client, 46.0, 11.0, 2000);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreatePrivacyZone_ShouldRefuseAnEleventhZone_WhenTenExist()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api);
        for (var i = 0; i < 10; i++)
            (await AddZoneAsync(rider.Client, 46.0 + i, 11.0, 500)).EnsureSuccessStatusCode();

        var response = await AddZoneAsync(rider.Client, 47.0, 11.0, 500);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task DeletePrivacyZone_ShouldNotDeleteAnotherMembersZone_WhenAskedByAnotherMember()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        var created = await AddZoneAsync(owner.Client, 46.0, 11.0, 500);
        var zone = (await created.Content.ReadFromJsonAsync<PrivacyZoneResponse>(Ct))!;

        var response = await other.Client.DeleteAsync($"/api/v1/privacy/zones/{zone.Id}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var mine = await owner.Client.GetFromJsonAsync<PrivacyResponse>("/api/v1/privacy", Ct);
        Assert.Single(mine!.Zones);
    }

    [Fact]
    public async Task PrivacySettings_ShouldStayPerMember_WhenAnotherMemberReadsTheirOwn()
    {
        await using var api = await StartAsync();
        var first = await NewMemberAsync(api);
        var second = await NewMemberAsync(api);
        (await first.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest
            {
                HideHeartRate = true,
                HidePower = true,
                HideCadence = true,
                HideSpeed = true,
                HideElevation = true,
                HideTemperature = true,
                TrimStartM = 300,
                TrimEndM = 300,
            },
            Ct)).EnsureSuccessStatusCode();

        var secondView = await second.Client.GetFromJsonAsync<PrivacyResponse>("/api/v1/privacy", Ct);

        Assert.False(secondView!.Streams.HideHeartRate);
        Assert.False(secondView.Streams.HidePower);
        Assert.Equal(0, secondView.TrimStartM);
        Assert.Empty(secondView.Zones);
    }

    [Fact]
    public async Task Privacy_ShouldAnswerUnauthorized_WhenTheTokenComesFromAnotherTenant()
    {
        await using var first = await StartAsync();
        await using var second = await StartAsync();
        var rider = await NewMemberAsync(first);
        var login = await first.LoginAsync(rider.Email, TestApi.MemberPassword);
        login.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await login.Content.ReadAsStringAsync(Ct));
        var client = second.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", json.RootElement.GetProperty("accessToken").GetString());

        var response = await client.GetAsync("/api/v1/privacy", Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static async Task<HttpResponseMessage> AddZoneAsync(HttpClient client, double latitude, double longitude, int radiusM) =>
        await client.PostAsJsonAsync(
            "/api/v1/privacy/zones",
            new CreatePrivacyZoneRequest
            {
                Name = $"Place {Guid.NewGuid():N}",
                Latitude = latitude,
                Longitude = longitude,
                RadiusM = radiusM,
            },
            Ct);

    /// <summary>Creates the club, rider and shared ride for a test, using the fixture given to the test class.</summary>
    private async Task<(Member Owner, AdminClubResponse Club, Member Rider, Guid RideId)> SharedRideAsync(TestApi api)
    {
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var rider = await NewMemberAsync(api);
        await JoinAsync(rider, club);
        var ride = await UploadAndWaitAsync(rider.Client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing", new
        {
            rides = "coaches",
            analytics = "coaches",
            routes = "coaches",
            wellbeing = "none",
        }, Ct)).EnsureSuccessStatusCode();
        return (owner, club, rider, ride.Id);
    }
}
