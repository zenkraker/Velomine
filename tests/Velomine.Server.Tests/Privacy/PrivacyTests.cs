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

public sealed class PrivacyTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<Member> NewMemberAsync(TestApi api) => api.NewMemberAsync();

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
    public async Task CoachRide_ShouldShowPowerAndItsNumbers_WhenTheRiderSharesRides()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        var rideId = await SharedRideAsync(api, rider);

        var ride = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);
        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.NotNull(ride!.AvgPowerW);
        Assert.NotNull(ride.MaxPowerW);
        Assert.NotNull(ride.NormalizedPowerW);
        Assert.NotNull(streams!.Power);
        Assert.NotNull(streams.HeartRate);
        // The training load and the power curve are numbers about the ride, so they come with it.
        Assert.Equal(HttpStatusCode.OK, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/power-curve", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training", Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachRide_ShouldShowHeartRate_WhenTheRiderSharesRides()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        var rideId = await SharedRideAsync(api, rider);

        var ride = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);
        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.NotNull(ride!.AvgHeartRate);
        Assert.NotNull(ride.MaxHeartRate);
        Assert.NotNull(streams!.HeartRate);
        Assert.NotNull(streams.Power);
    }

    [Fact]
    public async Task CoachRide_ShouldNotBeVisible_WhenTheRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var (_, club, rider) = await SharedClubAsync(api);
        var rideId = await SharedRideAsync(api, rider);
        var stranger = await NewMemberAsync(api);
        _ = await TestClubs.CreateAsync(api, stranger);

        var ride = await stranger.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);
        var streams = await stranger.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Equal(HttpStatusCode.NotFound, ride.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, streams.StatusCode);
    }

    [Fact]
    public async Task CoachStreams_ShouldStillTrimTheStartAndEnd_WhenTheRiderSetATrim()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await SetDefaultsAsync(rider.Client, PrivacyDefaults.None with { TrimStartM = 500, TrimEndM = 500 });
        var rideId = await SharedRideAsync(api, rider);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(streams!.Latitude![0]);
        Assert.Null(streams.Latitude[60]);
        Assert.NotNull(streams.Latitude[63]);
        // The ride is a 600-second FIT about 4.8 km long, so the last 500 m are the last few samples.
        Assert.Null(streams.Latitude[^1]);
        Assert.NotNull(streams.Latitude[streams.Latitude.Length / 2]);
    }

    [Fact]
    public async Task CoachStreams_ShouldHaveNoPositions_WhenThereIsNoRoutesGrant()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing", new
        {
            rides = "coaches",
            analytics = "coaches",
            routes = "none",
            wellbeing = "none",
        }, Ct)).EnsureSuccessStatusCode();
        var rideId = await SharedRideAsync(api, rider);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}/streams", Ct);

        Assert.Null(streams!.Latitude);
        Assert.Null(streams.Longitude);
        // The samples themselves are still a ride: only the positions need their own grant.
        Assert.NotNull(streams.Power);
        Assert.NotNull(streams.Time);
    }

    [Fact]
    public async Task UpdatePrivacy_ShouldAcceptAnOldApp_WhenItStillSendsTheSwitches()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api);

        var response = await rider.Client.PutAsJsonAsync(
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
                TrimEndM = 0,
            },
            Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var saved = (await response.Content.ReadFromJsonAsync<PrivacyResponse>(Ct))!;
        // The switches no longer exist, so they answer false whatever the app sends; the trim is saved as asked.
        Assert.False(saved.Streams.HideHeartRate);
        Assert.False(saved.Streams.HidePower);
        Assert.Equal(300, saved.TrimStartM);
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
            new UpdatePrivacyRequest { TrimStartM = 300, TrimEndM = 300 },
            Ct)).EnsureSuccessStatusCode();

        var secondView = await second.Client.GetFromJsonAsync<PrivacyResponse>("/api/v1/privacy", Ct);

        Assert.False(secondView!.Streams.HideHeartRate);
        Assert.False(secondView.Streams.HidePower);
        Assert.Equal(0, secondView.TrimStartM);
        Assert.Empty(secondView.Zones);
    }

    [Fact]
    public async Task Privacy_ShouldBeEachMembersOwn_WhenTwoMembersShareTheServer()
    {
        await using var api = await StartAsync();
        var first = await NewMemberAsync(api);
        var second = await NewMemberAsync(api);
        (await first.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest { TrimStartM = 900, TrimEndM = 0 },
            Ct)).EnsureSuccessStatusCode();

        var secondView = await second.Client.GetFromJsonAsync<PrivacyResponse>("/api/v1/privacy", Ct);

        Assert.False(secondView!.Streams.HideHeartRate);
        Assert.False(secondView.Streams.HidePower);
        Assert.Equal(0, secondView.TrimStartM);
        Assert.Empty(secondView.Zones);
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
        var (owner, club, rider) = await SharedClubAsync(api);
        return (owner, club, rider, await SharedRideAsync(api, rider));
    }

    /// <summary>A ride uploaded after the member's settings, so it keeps the privacy defaults it was imported with.</summary>
    private static async Task<Guid> SharedRideAsync(TestApi api, Member rider)
    {
        var ride = await UploadAndWaitAsync(rider.Client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));
        return ride.Id;
    }

    /// <summary>The club and the rider who shares rides, training and routes with its coaches.</summary>
    private async Task<(Member Owner, AdminClubResponse Club, Member Rider)> SharedClubAsync(TestApi api)
    {
        var owner = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, owner);
        var rider = await NewMemberAsync(api);
        await JoinAsync(rider, club);
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing", new
        {
            rides = "coaches",
            analytics = "coaches",
            routes = "coaches",
            wellbeing = "none",
        }, Ct)).EnsureSuccessStatusCode();
        return (owner, club, rider);
    }

    /// <summary>A ride keeps the trim it was imported with, so a test that wants it to apply saves it first.</summary>
    private static Task SetDefaultsAsync(HttpClient client, PrivacyDefaults defaults) =>
        client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest { TrimStartM = defaults.TrimStartM, TrimEndM = defaults.TrimEndM },
            Ct);
}
