using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// Story 7 through the API: the training view's weekly efficiency, what a coach sees when either signal is hidden,
/// a re-read filling the numbers, and the owner's ride staying the owner's.
/// </summary>
public sealed class EfficiencyTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC, so the member's week starts on Monday 2 November.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: name)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    /// <summary>
    /// The story's 85-minute ride: 15 minutes of warm-up at 150 W and 120 bpm, then 70 minutes at 200 W with 140 bpm
    /// for the first 35 and 147 for the last.
    /// </summary>
    private static byte[] DecouplingFit() =>
        Fit(new FitSession(
            Now.AddHours(-24).UtcDateTime,
            85 * 60,
            Power: s => s < 15 * 60 ? (short)150 : (short)200,
            HeartRate: s => s < 15 * 60 ? (short)120 : s < 15 * 60 + 35 * 60 ? (short)140 : (short)147));

    /// <summary>A 75-minute ride of one heart rate and one power, long enough to qualify.</summary>
    private static byte[] SteadyFit(int heartRate, int watts, int hoursAgo = 24) =>
        Fit(new FitSession(
            Now.AddHours(-hoursAgo).UtcDateTime,
            75 * 60,
            Power: _ => (short)watts,
            HeartRate: _ => (short)heartRate));

    private static async Task<RideResponse> UploadAsync(HttpClient client, byte[] file, string name = "ride.fit")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        return await TestApi.WaitForReadAsync(client, id);
    }

    private static Task<TrainingResponse> TrainingAsync(HttpClient client, int days = 30) =>
        client.GetFromJsonAsync<TrainingResponse>($"/api/v1/analytics/training?days={days}", Ct)!;

    [Fact]
    public async Task Training_ShouldAverageEfficiencyOfSteadyRidesPerWeek_WhenThereAreSeveral()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        // This week: 1.33 and 1.43 average 1.38. Last week: 1.25.
        Assert.Equal(1.33, (await UploadAsync(client, SteadyFit(150, 200, hoursAgo: 20))).EfficiencyFactor);
        Assert.Equal(1.43, (await UploadAsync(client, SteadyFit(140, 200, hoursAgo: 30))).EfficiencyFactor);
        Assert.Equal(1.25, (await UploadAsync(client, SteadyFit(160, 200, hoursAgo: 24 * 5))).EfficiencyFactor);

        var training = await TrainingAsync(client);

        Assert.Equal(2, training.Efficiency.Length);
        Assert.Equal(new DateOnly(2026, 10, 26), training.Efficiency[0].WeekStart);
        Assert.Equal(1.25, training.Efficiency[0].EfficiencyFactor);
        Assert.Equal(1, training.Efficiency[0].Rides);
        Assert.Equal(new DateOnly(2026, 11, 2), training.Efficiency[1].WeekStart);
        Assert.Equal(1.38, training.Efficiency[1].EfficiencyFactor);
        Assert.Equal(2, training.Efficiency[1].Rides);
    }

    [Fact]
    public async Task Training_ShouldLeaveOutAWeek_WhenItHasNoSteadyRide()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, SteadyFit(150, 200));

        var training = await TrainingAsync(client);

        Assert.Equal(new DateOnly(2026, 11, 2), Assert.Single(training.Efficiency).WeekStart);
    }

    [Fact]
    public async Task CoachRide_ShouldHideDecoupling_WhenHeartRateIsHidden()
    {
        await using var api = await StartAsync();
        var shared = await SharedRideAsync(api, heartRateHidden: true, powerHidden: false);

        var ride = await shared.Coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{shared.Club.Id}/athletes/{shared.AthleteId}/rides/{shared.RideId}", Ct);

        Assert.Null(ride!.DecouplingPct);
        Assert.Null(ride.EfficiencyFactor);
        Assert.Null(ride.Steady);
        Assert.NotNull(ride.NormalizedPowerW); // power is still shared
    }

    [Fact]
    public async Task CoachRide_ShouldHideDecoupling_WhenPowerIsHidden()
    {
        await using var api = await StartAsync();
        var shared = await SharedRideAsync(api, heartRateHidden: false, powerHidden: true);

        var ride = await shared.Coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{shared.Club.Id}/athletes/{shared.AthleteId}/rides/{shared.RideId}", Ct);

        Assert.Null(ride!.DecouplingPct);
        Assert.Null(ride.EfficiencyFactor);
        Assert.Null(ride.Steady);
        Assert.NotNull(ride.AvgHeartRate); // heart rate is still shared
    }

    [Fact]
    public async Task CoachTraining_ShouldLeaveOutARideWhoseHeartRateIsHidden_WhenItIsNoSteadyOne()
    {
        // The coach's training view needs both signals shared (it is built from TSS and TRIMP), so a ride whose
        // heart rate is hidden is left out of the weekly efficiency too, even when its own snapshot says steady.
        await using var api = await StartAsync();
        var shared = await SharedRideAsync(api, heartRateHidden: false, powerHidden: false);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.Id == shared.RideId)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.HideHeartRate, (bool?)true), Ct);
        }

        var training = await shared.Coach.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{shared.Club.Id}/athletes/{shared.AthleteId}/training?days=30", Ct);

        Assert.Empty(training!.Efficiency);
    }

    [Fact]
    public async Task RideReparse_ShouldFillEfficiency_WhenAnOlderRideIsReadAgain()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        var ride = await UploadAsync(client, DecouplingFit());

        // What an older parser left behind: no numbers, and a version below the current one.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.Id == ride.Id).ExecuteUpdateAsync(s => s
                .SetProperty(r => r.EfficiencyFactor, (double?)null)
                .SetProperty(r => r.DecouplingPct, (double?)null)
                .SetProperty(r => r.Steady, (bool?)null)
                .SetProperty(r => r.ParserVersion, RideParserVersion.Current - 1), Ct);
        }

        await api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct);

        var again = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct);
        // The kept seconds' own normalized power (200 W), not the ride's, which the warm-up drags below it.
        Assert.Equal(1.39, again!.EfficiencyFactor);
        Assert.Equal(4.8, again.DecouplingPct);
        Assert.True(again.Steady);
    }

    [Fact]
    public async Task Ride_ShouldNotBeVisible_WhenTheRideBelongsToAnotherMember()
    {
        await using var api = await StartAsync();
        var (owner, _) = await NewMemberAsync(api);
        var ride = await UploadAsync(owner, DecouplingFit());
        var (stranger, _) = await NewMemberAsync(api, "Someone Else");

        var response = await stranger.GetAsync($"/api/v1/rides/{ride.Id}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private sealed record Shared(HttpClient Coach, AdminClubResponse Club, Guid AthleteId, Guid RideId);

    /// <summary>
    /// An athlete in a coach's club: one decoupling ride, rides and analytics shared, and the privacy switches set
    /// before the ride because the snapshot is copied at import.
    /// </summary>
    private static async Task<Shared> SharedRideAsync(TestApi api, bool heartRateHidden, bool powerHidden)
    {
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(ownerEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, ownerEmail);
        var (athlete, athleteId) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        (await athlete.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        // The privacy snapshot is copied onto a ride at import, so it is set before the ride is read.
        (await athlete.PutAsJsonAsync("/api/v1/privacy/settings", new UpdatePrivacyRequest
        {
            HideHeartRate = heartRateHidden,
            HidePower = powerHidden,
            HideCadence = false,
            HideSpeed = false,
            HideElevation = false,
            HideTemperature = false,
            TrimStartM = 0,
            TrimEndM = 0,
        }, Ct)).EnsureSuccessStatusCode();

        var ride = await UploadAsync(athlete, DecouplingFit());
        Assert.Equal(4.8, ride.DecouplingPct);
        return new Shared(coach, club, athleteId, ride.Id);
    }
}
