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
public sealed class RidePrivacySnapshotTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task SetDefaultsAsync(HttpClient client, int trimStartM, int trimEndM = 0) =>
        (await client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new UpdatePrivacyRequest { TrimStartM = trimStartM, TrimEndM = trimEndM },
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
    public async Task Trim_ShouldStayOnAnOlderRide_WhenTheMemberSetsTrimmingAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        var ride = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, trimStartM: 500);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{ride.Id}/streams", Ct);

        // Imported untrimmed, so the first sample keeps its position even though trimming is on now.
        Assert.NotNull(streams!.Latitude![0]);
    }

    [Fact]
    public async Task Trim_ShouldStayOnAnOlderRide_WhenTheMemberTurnsTrimmingOffAfterwards()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await SetDefaultsAsync(rider.Client, trimStartM: 500);
        var old = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));
        await SetDefaultsAsync(rider.Client, trimStartM: 0);
        var fresh = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start.AddDays(1), 600)));

        var oldStreams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{old.Id}/streams", Ct);
        var freshStreams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{fresh.Id}/streams", Ct);

        // The old ride keeps the trim it was imported with; the new one starts at its first sample.
        Assert.Null(oldStreams!.Latitude![0]);
        Assert.NotNull(freshStreams!.Latitude![0]);
    }

    [Fact]
    public async Task UploadRide_ShouldCopyThePrivacyDefaults_WhenTheMemberHasSavedThem()
    {
        await using var api = await StartAsync();
        var rider = await api.NewMemberAsync();
        await SetDefaultsAsync(rider.Client, trimStartM: 600);

        var ride = await TestApi.UploadAndWaitAsync(rider.Client, Fit(new FitSession(Start, 600)));

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var stored = await db.Rides.AsNoTracking().SingleAsync(r => r.Id == ride.Id, Ct);
        Assert.Equal(new PrivacyDefaults(600, 0), stored.Privacy);
        // The six switch columns stay valid for their last release: a new import writes them false.
        Assert.False(stored.HidePower);
        Assert.False(stored.HideHeartRate);
    }

    [Fact]
    public async Task UploadRide_ShouldCopyThePrivacyDefaultsOntoEveryActivity_WhenOneFileHoldsSeveral()
    {
        await using var api = await StartAsync();
        var rider = await api.NewMemberAsync();
        await SetDefaultsAsync(rider.Client, trimStartM: 900);
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
        Assert.All(rides, ride => Assert.Equal(900, ride.TrimStartM));
    }
}
