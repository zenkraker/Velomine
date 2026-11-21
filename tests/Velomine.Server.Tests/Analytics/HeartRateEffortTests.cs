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
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// A ride's effort score is the first that exists: TSS from power, then hrTSS from heart rate, then how hard it felt.
/// Fitness, fatigue, form and readiness follow it, so a rider with only a heart-rate strap builds a chart; a coach
/// gets the daily load under the grant that reaches the training range, and the feel score only with wellbeing.
/// </summary>
public sealed class HeartRateEffortTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static async Task SetHeartRatesAsync(HttpClient client, int max, int threshold)
    {
        (await client.PutAsJsonAsync("/api/v1/accounts/me/heart-rate/max", new SetHeartRateRequest(max), Ct))
            .EnsureSuccessStatusCode();
        (await client.PutAsJsonAsync("/api/v1/accounts/me/heart-rate/threshold", new SetHeartRateRequest(threshold), Ct))
            .EnsureSuccessStatusCode();
    }

    /// <summary>A ready ride saved straight into the database, as a first read leaves it, with an optional rating.</summary>
    private static async Task<Guid> AddRideAsync(
        TestApi api,
        Guid userId,
        double hours = 1,
        double? tss = null,
        double? hrTss = null,
        int? rpe = null,
        string startUtc = "2026-11-04T07:00:00",
        bool? hidePower = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var ride = new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Status = RideStatus.Ready,
            FileSha256 = Guid.NewGuid().ToString("N"),
            FileName = "ride.fit",
            UploadedAt = Now,
            StartTime = DateTimeOffset.Parse(startUtc + "Z"),
            MovingS = hours * 3600,
            DistanceM = hours * 40_000,
            Tss = tss,
            HrTss = hrTss,
            HidePower = hidePower,
            HideHeartRate = hidePower is null ? null : false,
            HideCadence = hidePower is null ? null : false,
            HideSpeed = hidePower is null ? null : false,
            HideElevation = hidePower is null ? null : false,
            HideTemperature = hidePower is null ? null : false,
        };
        db.Rides.Add(ride);
        if (rpe is { } rating) db.RideFeels.Add(new RideFeel { RideId = ride.Id, Rpe = rating, UpdatedAt = Now });
        await db.SaveChangesAsync(Ct);
        return ride.Id;
    }

    private static async Task<TrainingResponse> TrainingAsync(HttpClient client, int days = 7) =>
        (await client.GetFromJsonAsync<TrainingResponse>($"/api/v1/analytics/training?days={days}", Ct))!;

    private static double DayLoad(TrainingResponse training) => training.Days[^1].Load;

    private static async Task JoinAndShareAsync(
        TestApi api,
        TestMember rider,
        AdminClubResponse club,
        string wellbeing = "none")
    {
        (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest
            {
                Rides = "coaches",
                Analytics = "coaches",
                Routes = "none",
                Wellbeing = wellbeing,
            },
            Ct)).EnsureSuccessStatusCode();
    }

    [Fact]
    public void TrainingLoad_Effort_ShouldUseTheEstimatedTss_WhenThereIsNoPowerHeartRateOrFeel() =>
        Assert.Equal((42.0, EffortSources.Estimated), TrainingLoad.Effort(null, null, null, 42.0));

    [Fact]
    public void TrainingLoad_Effort_ShouldPreferTheFeelScore_WhenTheRideAlsoHasAnEstimate() =>
        Assert.Equal((100.0, EffortSources.Feel), TrainingLoad.Effort(null, null, 100.0, 42.0));

    [Fact]
    public async Task Training_ShouldCountTheEstimatedTss_WhenARideHasNoSensors()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // Watts are estimated only when the rider has a weight.
        (await member.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, 70, 2000, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        // A GPX with speed from the positions and a slope from the altitude, but no power and no heart rate.
        var uploaded = await TestApi.UploadAndWaitAsync(
            member.Client, Bytes(Gpx(600, start: new DateTime(2026, 11, 4, 7, 0, 0, DateTimeKind.Utc))),
            "ride.gpx");

        var training = await TrainingAsync(member.Client);
        var stored = await RideInDbAsync(api, uploaded.Id);

        Assert.NotNull(stored.EstimatedTss);
        Assert.Equal(stored.EstimatedTss, DayLoad(training));
        Assert.Equal(0, training.Tss);
    }

    [Fact]
    public async Task GetRide_ShouldSayEstimated_WhenTheEffortComesFromEstimatedWatts()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, 70, 2000, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        var uploaded = await TestApi.UploadAndWaitAsync(
            member.Client, Bytes(Gpx(600, start: new DateTime(2026, 11, 4, 7, 0, 0, DateTimeKind.Utc))),
            "ride.gpx");

        var ride = await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{uploaded.Id}", Ct);
        var stored = await RideInDbAsync(api, uploaded.Id);

        Assert.Equal(EffortSources.Estimated, ride!.EffortSource);
        Assert.Equal(stored.EstimatedTss, ride.EffortScore);
    }

    [Fact]
    public async Task Training_ShouldUseTheFeelScore_WhenARideHasNoPowerAndNoHeartRate()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // An hour rated 7 of 10 is the feel score's threshold: 100, on the same scale as TSS.
        await AddRideAsync(api, member.Id, tss: null, hrTss: null, rpe: 7);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(100, DayLoad(training));
        Assert.True(training.Days[^1].Fitness > 0);
        Assert.Equal(0, training.Tss);
        Assert.Equal(0, training.HeartRateLoadRides);
    }

    [Fact]
    public async Task Training_ShouldPreferHeartRate_WhenARideHasBoth()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A heart-rate score and a rating: the heart rate is the better evidence, so the feel score is not used.
        await AddRideAsync(api, member.Id, hrTss: 70, rpe: 7);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(70, DayLoad(training));
        Assert.Equal(1, training.HeartRateLoadRides);
    }

    [Fact]
    public async Task Training_ShouldPreferPower_WhenARideHasBoth()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddRideAsync(api, member.Id, tss: 45, hrTss: 70, rpe: 7);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(45, DayLoad(training));
        Assert.Equal(0, training.HeartRateLoadRides);
    }

    [Fact]
    public async Task Training_ShouldCountHeartRateRides_WhenThereIsNoPower()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        for (var day = 29; day <= 31; day++)
            await AddRideAsync(api, member.Id, hrTss: 50, startUtc: $"2026-10-{day}T07:00:00");
        for (var day = 1; day <= 4; day++)
            await AddRideAsync(api, member.Id, hrTss: 50, startUtc: $"2026-11-0{day}T07:00:00");

        var training = await TrainingAsync(member.Client);

        Assert.True(training.Days[^1].Fitness > 0);
        Assert.Equal(350, training.Days.Sum(d => d.Load));
        Assert.Equal(0, training.Tss);
        // The progress page notes the heart-rate rides it counted.
        Assert.Equal(7, training.HeartRateLoadRides);
    }

    [Fact]
    public async Task Readiness_ShouldUseTheEffortScore_WhenTheRiderHasNoPowerMeter()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddRideAsync(api, member.Id, hrTss: 100, startUtc: "2026-11-04T07:00:00");

        var readiness = await member.Client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);

        // The recent load is today's effort score and yesterday's, so the heart-rate ride is in it.
        var recent = Assert.Single(readiness!.Factors, f => f.Key == "recentLoad");
        Assert.Equal(100, recent.Value);
        Assert.NotNull(readiness.Score);
    }

    [Fact]
    public async Task CoachTraining_ShouldSkipTheFeelScore_WhenThereIsNoWellbeingGrant()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, rpe: 7);

        var training = await coach.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(0, DayLoad(training!));
        Assert.Equal(0, training!.Days[^1].Fitness);
    }

    [Fact]
    public async Task CoachTraining_ShouldCountFeel_WhenTheWellbeingGrantExists()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club, wellbeing: "coaches");
        await AddRideAsync(api, rider.Id, rpe: 7);

        var training = await coach.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(100, DayLoad(training!));
    }

    [Fact]
    public async Task CoachTraining_ShouldCountAHiddenRidesLoad_WhenThePowerSwitchIsOff()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        // The ride's own snapshot hides power; hrTSS counts like TSS, so the daily total is not redacted.
        await AddRideAsync(api, rider.Id, hrTss: 80, hidePower: true);

        var training = await coach.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(80, DayLoad(training!));
    }

    [Fact]
    public async Task CoachTraining_ShouldNotCountItsFeel_WhenThereIsNoWellbeingGrant()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, hrTss: null, rpe: 7, hidePower: true);

        var training = await coach.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(0, DayLoad(training!));
    }

    [Fact]
    public async Task CoachRoster_ShouldUseTheEffortScore_WhenTheAthleteHasNoPower()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, hrTss: 90, startUtc: "2026-11-04T07:00:00");

        // A rider of another club, so the roster proves it lists one club's members only.
        var stranger = await api.NewMemberAsync();
        var otherClub = await TestClubs.CreateAsync(api, stranger);
        var outsider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, outsider, otherClub);
        await AddRideAsync(api, outsider.Id, hrTss: 90);

        var roster = await coach.Client.GetFromJsonAsync<CoachAthletesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes", Ct);

        var athlete = Assert.Single(roster!.Athletes);
        Assert.Equal(rider.Id, athlete.UserId);
        Assert.Equal(90, athlete.Tss7);
        Assert.Equal(90, athlete.Tss42);
    }

    [Fact]
    public async Task CoachAthlete_ShouldCountHeartRateLoad_WhenTheRideHasNoPower()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, hrTss: 90, startUtc: "2026-11-04T07:00:00");

        var athlete = await coach.Client.GetFromJsonAsync<CoachAthleteResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}", Ct);
        var roster = await coach.Client.GetFromJsonAsync<CoachAthletesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes", Ct);

        // One athlete's page and the roster agree: the effort score, not the stored TSS, which is null here.
        Assert.Equal(90, athlete!.Tss7);
        Assert.Equal(athlete.Tss7, Assert.Single(roster!.Athletes).Tss7);
        Assert.Equal(90, athlete.Tss42);
    }

    [Fact]
    public async Task CoachAthlete_ShouldNotCountTheFeelScore_WhenThereIsNoWellbeingGrant()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, rpe: 7);

        var without = await coach.Client.GetFromJsonAsync<CoachAthleteResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}", Ct);
        Assert.Equal(0, without!.Tss7);
        Assert.Equal(0, without.Tss42);

        (await rider.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest
            {
                Rides = "coaches",
                Analytics = "coaches",
                Routes = "none",
                Wellbeing = "coaches",
            },
            Ct)).EnsureSuccessStatusCode();
        var with = await coach.Client.GetFromJsonAsync<CoachAthleteResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}", Ct);

        // An hour rated 7 of 10 is 100 on the TSS scale, and the grant is what makes it readable.
        Assert.Equal(100, with!.Tss7);
        Assert.Equal(100, with.Tss42);
    }

    [Fact]
    public async Task CoachAthlete_ShouldShowNoLoad_WhenTheRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        await AddRideAsync(api, rider.Id, hrTss: 90);

        var stranger = await api.NewMemberAsync();
        _ = await TestClubs.CreateAsync(api, stranger);

        var athlete = await stranger.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{rider.Id}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, athlete.StatusCode);
    }

    [Fact]
    public async Task ClubData_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        var rideId = await AddRideAsync(api, rider.Id, hrTss: 60);

        var stranger = await api.NewMemberAsync();
        _ = await TestClubs.CreateAsync(api, stranger);

        var training = await stranger.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);
        var ride = await stranger.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, training.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, ride.StatusCode);
    }

    [Fact]
    public async Task RideResponse_ShouldNotCarryTheEffortScore_WhenAViewerReadsIt()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        await JoinAndShareAsync(api, rider, club);
        var rideId = await AddRideAsync(api, rider.Id, hrTss: 60);

        var own = await rider.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{rideId}", Ct);
        var shown = await coach.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);

        // The owner reads the score and where it came from; a coach reads neither, nor the stored hrTSS.
        Assert.Equal((60.0, EffortSources.HeartRate), (own!.EffortScore, own.EffortSource));
        Assert.Equal(60.0, own.HrTss);
        Assert.Null(shown!.EffortScore);
        Assert.Null(shown.EffortSource);
        Assert.Null(shown.HrTss);
    }

    [Fact]
    public async Task RideResponse_ShouldSayTheEffortCameFromTheFeel_WhenTheRiderRatedTheRide()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var rideId = await AddRideAsync(api, member.Id, rpe: 7);

        var ride = await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{rideId}", Ct);

        Assert.Equal((100.0, EffortSources.Feel), (ride!.EffortScore, ride.EffortSource));
    }

    /// <summary>Sets a number straight on the account, as the heart-rate endpoints would.</summary>
    private static async Task SetThresholdAsync(TestApi api, Guid userId, int? max, int? threshold)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.FirstAsync(u => u.Id == userId, Ct);
        user.MaxHeartRateBpm = max;
        user.MaxHeartRateSource = max is null ? null : HeartRateSources.Manual;
        user.ThresholdHeartRateBpm = threshold;
        user.ThresholdHeartRateSource = threshold is null ? null : HeartRateSources.Manual;
        await db.SaveChangesAsync(Ct);
    }

    private static Task ReparseAsync(TestApi api) =>
        api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct);

    private static async Task<Ride> RideInDbAsync(TestApi api, Guid rideId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.Rides.AsNoTracking().FirstAsync(r => r.Id == rideId, Ct);
    }

    /// <summary>A ride of ten minutes at 160 bpm, uploaded and read like any other.</summary>
    private static Task<RideResponse> UploadAsync(TestMember member) =>
        TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(new DateTime(2026, 11, 3, 7, 0, 0), 600, HeartRate: _ => 160)));

    [Fact]
    public async Task RideReparse_ShouldKeepTheFirstThreshold_WhenTheRiderChangedIt()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetThresholdAsync(api, member.Id, max: 185, threshold: 150);
        var ride = await UploadAsync(member);
        // 599 seconds at 160 bpm against a threshold of 150: 18.9.
        var first = await RideInDbAsync(api, ride.Id);
        Assert.Equal((150, 18.9), (first.LoadThresholdHeartRate, first.HrTss));

        // The rider retypes the number, and a later parser version reads the ride again from its file.
        await SetThresholdAsync(api, member.Id, max: 185, threshold: 170);
        await MarkBelowCurrentAsync(api, ride.Id);
        await ReparseAsync(api);

        var again = await RideInDbAsync(api, ride.Id);
        Assert.Equal((150, 18.9), (again.LoadThresholdHeartRate, again.HrTss));
    }

    [Fact]
    public async Task RideReparse_ShouldStampTheCurrentThreshold_WhenTheRideHadNone()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetThresholdAsync(api, member.Id, max: 185, threshold: 150);
        var ride = await UploadAsync(member);
        // A ride read before the column existed: no threshold recorded and no heart-rate score.
        await ForgetThresholdAsync(api, ride.Id);
        await SetThresholdAsync(api, member.Id, max: 185, threshold: 170);

        await ReparseAsync(api);

        var again = await RideInDbAsync(api, ride.Id);
        // The same 599 seconds against 170 instead of 150: 14.7.
        Assert.Equal((170, 14.7), (again.LoadThresholdHeartRate, again.HrTss));
    }

    /// <summary>Puts a read ride below the current parser version, so the re-reader picks it up.</summary>
    private static async Task MarkBelowCurrentAsync(TestApi api, Guid rideId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var ride = await db.Rides.FirstAsync(r => r.Id == rideId, Ct);
        // The bump that sends every old ride through the re-reader is Story 6's commit; here the version is set by hand.
        ride.ParserVersion = RideParserVersion.Current - 1;
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>Leaves the ride as a read before the threshold was recorded had it.</summary>
    private static async Task ForgetThresholdAsync(TestApi api, Guid rideId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var ride = await db.Rides.FirstAsync(r => r.Id == rideId, Ct);
        ride.ParserVersion = RideParserVersion.Current - 1;
        ride.LoadThresholdHeartRate = null;
        ride.HrTss = null;
        await db.SaveChangesAsync(Ct);
    }
}
