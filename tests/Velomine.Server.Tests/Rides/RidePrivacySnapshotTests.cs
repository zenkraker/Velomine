using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// A ride keeps the privacy defaults it was imported with: changing the member's defaults later changes what a viewer
/// sees of a new ride only, never of an older one.
/// </summary>
[Collection("postgres")]
public sealed class RidePrivacySnapshotTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task SetDefaultsAsync(HttpClient client, bool hidePower, int trimStartM) =>
        (await client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest
            {
                HideHeartRate = false,
                HidePower = hidePower,
                HideCadence = false,
                HideSpeed = false,
                HideElevation = false,
                HideTemperature = false,
                TrimStartM = trimStartM,
                TrimEndM = 0,
            },
            Ct)).EnsureSuccessStatusCode();

    /// <summary>An owner and a rider who shares their rides, training and routes with the club's coaches.</summary>
    private static async Task<(TestMember Owner, AdminClubResponse Club, TestMember Rider)> SharedClubAsync(TestApi api)
    {
        var owner = await api.NewMemberAsync();
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var created = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = owner.Email },
            Ct);
        created.EnsureSuccessStatusCode();
        var club = (await created.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;

        var rider = await api.NewMemberAsync();
        (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing", new
        {
            rides = "coaches",
            analytics = "coaches",
            routes = "coaches",
            wellbeing = "none",
        }, Ct)).EnsureSuccessStatusCode();
        return (owner, club, rider);
    }

    [Fact]
    public async Task PrivacySettings_ShouldStayOnAnOlderRide_WhenTheMemberRelaxesTheDefaultAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await SetDefaultsAsync(rider.Client, hidePower: true, trimStartM: 0);
        var old = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, hidePower: false, trimStartM: 0);
        var fresh = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start.AddDays(1), 600)));

        var oldView = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{old.Id}", Ct);
        var freshView = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{fresh.Id}", Ct);

        Assert.Null(oldView!.AvgPowerW);
        Assert.Null(oldView.NormalizedPowerW);
        Assert.NotNull(freshView!.AvgPowerW);
        Assert.NotNull(freshView.NormalizedPowerW);
    }

    [Fact]
    public async Task PrivacySettings_ShouldStayOnAnOlderRideInTheList_WhenTheMemberRelaxesTheDefaultAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await SetDefaultsAsync(rider.Client, hidePower: true, trimStartM: 0);
        var old = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, hidePower: false, trimStartM: 0);
        var fresh = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start.AddDays(1), 600)));

        var list = await owner.Client.GetFromJsonAsync<ListRidesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides", Ct);

        Assert.Null(list!.Rides.Single(r => r.Id == old.Id).AvgPowerW);
        Assert.NotNull(list.Rides.Single(r => r.Id == fresh.Id).AvgPowerW);
    }

    [Fact]
    public async Task PrivacySettings_ShouldStayOnAnOlderRideStreams_WhenTheMemberRelaxesTheDefaultAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await SetDefaultsAsync(rider.Client, hidePower: true, trimStartM: 0);
        var old = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, hidePower: false, trimStartM: 0);

        var oldStreams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{old.Id}/streams", Ct);

        Assert.Null(oldStreams!.Power);
        Assert.NotNull(oldStreams.HeartRate);
    }

    [Fact]
    public async Task TrimStart_ShouldStayOnAnOlderRide_WhenTheMemberSetsTrimmingAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        var ride = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, hidePower: false, trimStartM: 500);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{ride.Id}/streams", Ct);

        // Imported untrimmed, so the first sample keeps its position even though trimming is on now.
        Assert.NotNull(streams!.Latitude![0]);
    }

    [Fact]
    public async Task UploadRide_ShouldCopyThePrivacyDefaults_WhenTheMemberHasSavedThem()
    {
        await using var api = await StartAsync();
        var rider = await api.NewMemberAsync();
        await SetDefaultsAsync(rider.Client, hidePower: true, trimStartM: 600);

        var ride = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var stored = await db.Rides.AsNoTracking().SingleAsync(r => r.Id == ride.Id, Ct);
        Assert.Equal(new PrivacyDefaults(false, true, false, false, false, false, 600, 0), stored.Privacy);
    }

    [Fact]
    public async Task UploadRide_ShouldCopyThePrivacyDefaultsOntoEveryActivity_WhenOneFileHoldsSeveral()
    {
        await using var api = await StartAsync();
        var rider = await api.NewMemberAsync();
        await SetDefaultsAsync(rider.Client, hidePower: true, trimStartM: 0);
        // One file, two activities: the first fills the uploaded row, the second gets a row of its own.
        var file = Fit(new FitSession(Start, 600), new FitSession(Start.AddHours(3), 600));

        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", "two.fit" } };
        (await rider.Client.PostAsync("/api/v1/rides/uploads", form, Ct)).EnsureSuccessStatusCode();
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var rides = new List<Ride>();
        for (var i = 0; i < 100; i++)
        {
            rides = await db.Rides.AsNoTracking().Where(r => r.UserId == rider.Id).ToListAsync(Ct);
            if (rides.Count == 2 && rides.All(r => r.Status != RideStatus.Processing)) break;
            await Task.Delay(100, Ct);
        }

        Assert.Equal(2, rides.Count);
        Assert.All(rides, ride => Assert.True(ride.HidePower));
    }
}
