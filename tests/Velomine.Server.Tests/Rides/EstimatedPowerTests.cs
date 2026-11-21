using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
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

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// Estimated watts for a ride with no power meter: the formula against hand-computed numbers, when the ride may have
/// them at all, and what a coach and a re-read see of them.
/// </summary>
public sealed class EstimatedPowerTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: name)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    private static Task SetProfileAsync(HttpClient client, int? ftpW, double? weightKg) =>
        client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", ftpW, weightKg, 2000, "UTC", "monday"),
            Ct);

    /// <summary>
    /// One sample per second, flat unless said, with positions moving north at the same speed so a file without speed
    /// still has one. The altitude is constant, so a flat ride has no grade.
    /// </summary>
    private static Sample[] Ride(
        int seconds,
        double metresPerSecond = 8,
        bool speedInFile = true,
        short? power = null,
        float? altitude = 300)
    {
        var samples = new Sample[seconds];
        for (var i = 0; i < seconds; i++)
            samples[i] = new Sample(
                T: i,
                Latitude: 46.0 + i * metresPerSecond / 111_195.0,
                Longitude: 11.0,
                Altitude: altitude,
                Speed: speedInFile ? (float)metresPerSecond : null,
                Power: power);
        return samples;
    }

    private static PowerEstimate Estimate(
        double? riderWeightKg = 70,
        string? bikeKind = "road",
        double? bikeWeightKg = null,
        string? discipline = null,
        string? environment = null,
        string? assist = null) =>
        new(riderWeightKg, bikeWeightKg, bikeKind, discipline, environment, assist);

    /// <summary>The power model at sea level, with the row of a kind of bike; 80 kg is the story's 70 kg rider and 10 kg bike.</summary>
    private static double Watts(
        double speedMs,
        double grade,
        double massKg = 80,
        string kind = "road",
        double altitudeM = 0)
    {
        var (crr, cda, _) = EstimatedPower.Row(kind);
        return EstimatedPower.Watts(speedMs, 0, grade, massKg, crr, cda, altitudeM);
    }

    [Fact]
    public void EstimatedPower_ShouldBe186W_WhenClimbingFivePercentAt4MetresPerSecond() =>
        Assert.Equal(186, Math.Round(Watts(4, 0.05)));

    [Fact]
    public void EstimatedPower_ShouldBe143W_WhenRidingFlatAt30KmPerHour() =>
        Assert.Equal(143, Math.Round(Watts(30_000 / 3600.0, 0)));

    [Fact]
    public void EstimatedPower_ShouldBe89W_WhenRidingGravelFlatAt6MetresPerSecond() =>
        Assert.Equal(89, Math.Round(Watts(6, 0, massKg: 83, kind: "gravel")));

    [Fact]
    public void EstimatedPower_ShouldBeZero_WhenDescending() =>
        Assert.Equal(0, Watts(12, -0.06));

    [Fact]
    public void EstimatedPower_ShouldBeLower_WhenTheAirIsThinner() =>
        Assert.Equal(184, Math.Round(Watts(4, 0.05, altitudeM: 1500)));

    [Fact]
    public void EstimatedPower_ShouldBeComputed_WhenEnvironmentIsUnknown()
    {
        var metrics = RideMetrics.Compute(Ride(60), estimate: Estimate(environment: null));

        Assert.NotNull(metrics.EstimatedPower);
        Assert.NotNull(metrics.EstimatedAvgPowerW);
    }

    [Fact]
    public void EstimatedPower_ShouldBeComputed_WhenSpeedComesFromPositions()
    {
        var metrics = RideMetrics.Compute(Ride(60, speedInFile: false), estimate: Estimate());

        Assert.Equal(SpeedSource.Gps, metrics.SpeedSource);
        Assert.NotNull(metrics.EstimatedAvgPowerW);
    }

    [Fact]
    public void EstimatedPower_ShouldNotBeComputed_WhenTheRideHasPower()
    {
        var metrics = RideMetrics.Compute(Ride(60, power: 200), estimate: Estimate());

        Assert.Null(metrics.EstimatedPower);
        Assert.Null(metrics.EstimatedAvgPowerW);
        Assert.Equal(200, metrics.AvgPowerW);
    }

    [Fact]
    public void EstimatedPower_ShouldNotBeComputed_WhenTheBikeIsAnEbike() =>
        Assert.Null(RideMetrics.Compute(Ride(60), estimate: Estimate(bikeKind: "ebike")).EstimatedAvgPowerW);

    [Fact]
    public void EstimatedPower_ShouldNotBeComputed_WhenItIsAnEbikeRide() =>
        Assert.Null(RideMetrics.Compute(Ride(60), estimate: Estimate(assist: "ebike")).EstimatedAvgPowerW);

    [Fact]
    public void EstimatedPower_ShouldNotBeComputed_WhenItIsIndoors() =>
        Assert.Null(RideMetrics.Compute(Ride(60), estimate: Estimate(environment: "indoor")).EstimatedAvgPowerW);

    [Fact]
    public void EstimatedPower_ShouldNotBeComputed_WhenTheRiderHasNoWeight() =>
        Assert.Null(RideMetrics.Compute(Ride(60), estimate: Estimate(riderWeightKg: null)).EstimatedAvgPowerW);

    [Fact]
    public void EstimatedPower_ShouldUseTheBikeWeight_WhenTheBikeHasOne()
    {
        var withDefault = RideMetrics.Compute(Ride(60), estimate: Estimate());
        var withOwnWeight = RideMetrics.Compute(Ride(60), estimate: Estimate(bikeWeightKg: 20));

        Assert.True(withOwnWeight.EstimatedAvgPowerW > withDefault.EstimatedAvgPowerW);
    }

    [Fact]
    public async Task EstimatedPower_ShouldNotChangeThePowerCurve_WhenARideHasOnlyEstimatedWatts()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await SetProfileAsync(client, ftpW: null, weightKg: 75);
        var ride = await TestApi.UploadAndWaitAsync(client, Fit(new FitSession(Recent(), 600, NoPower: true)));

        Assert.NotNull(ride.EstimatedAvgPowerW);
        Assert.Null(ride.AvgPowerW);
        Assert.Null(ride.NormalizedPowerW);

        var curve = await client.GetFromJsonAsync<PowerCurveResponse>("/api/v1/analytics/power-curve?days=90", Ct);
        Assert.False(curve!.HasPower);
        Assert.Empty(curve.Points);
    }

    [Fact]
    public async Task EstimatedTss_ShouldUseTwoAndAHalfWattsPerKilo_WhenTheRiderHasNoFtp()
    {
        await using var api = await StartAsync();
        var (client, userId) = await NewMemberAsync(api);
        await SetProfileAsync(client, ftpW: null, weightKg: 70);
        await TestApi.UploadAndWaitAsync(client, Fit(new FitSession(Recent(), 600, NoPower: true)));

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var ride = await db.Rides.AsNoTracking().SingleAsync(r => r.UserId == userId, Ct);
        var (_, tss) = TrainingLoad.PowerLoad(ride.EstimatedNormalizedPowerW, ride.MovingS ?? 0, 175);

        Assert.NotNull(ride.EstimatedTss);
        Assert.Equal(tss, ride.EstimatedTss);
        // The stand-in is never stored as the rider's FTP.
        Assert.Null((await db.Users.AsNoTracking().SingleAsync(u => u.Id == userId, Ct)).FtpW);
    }

    [Fact]
    public async Task RideReparse_ShouldEstimateWatts_WhenTheParserVersionRises()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        var ride = await TestApi.UploadAndWaitAsync(client, Fit(new FitSession(Recent(), 120, NoPower: true)));
        Assert.Null(ride.EstimatedAvgPowerW); // no weight yet, so nothing to estimate from

        await SetProfileAsync(client, ftpW: null, weightKg: 70);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.Id == ride.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ParserVersion, RideParserVersion.Current - 1), Ct);
        }

        await api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct);

        var again = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct);
        Assert.NotNull(again!.EstimatedAvgPowerW);
    }

    [Fact]
    public async Task CoachRide_ShouldShowEstimatedPower_WhenTheRideHasNoSensors()
    {
        await using var api = await StartAsync();
        var shared = await SharedRideAsync(api);

        var coachRide = await shared.Coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{shared.Club.Id}/athletes/{shared.AthleteId}/rides/{shared.RideId}", Ct);

        // A coach reads the estimate like the other numbers; an estimate is what the ride has, not a hidden switch.
        Assert.NotNull(coachRide!.EstimatedAvgPowerW);
        Assert.Null(coachRide.AvgPowerW);
    }

    [Fact]
    public async Task CoachStreams_ShouldCarryEstimatedPower_WhenTheRideHasNoSensors()
    {
        await using var api = await StartAsync();
        var shared = await SharedRideAsync(api);

        var coachStreams = await shared.Coach.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{shared.Club.Id}/athletes/{shared.AthleteId}/rides/{shared.RideId}/streams", Ct);

        Assert.NotNull(coachStreams!.EstimatedPower);
        // The owner reads the same samples, so the chart draws the same line for both.
        var ownerStreams = await shared.Athlete.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/rides/{shared.RideId}/streams", Ct);
        Assert.Equal(ownerStreams!.EstimatedPower, coachStreams.EstimatedPower);
    }

    /// <summary>A ride two hours ago, so it is not today's and cannot clash with another test's ride.</summary>
    private static DateTime Recent() => DateTime.UtcNow.AddHours(-2);

    private sealed record Shared(HttpClient Coach, HttpClient Athlete, AdminClubResponse Club, Guid AthleteId, Guid RideId);

    /// <summary>An athlete in a coach's club with a sensorless ride, rides and analytics shared.</summary>
    private static async Task<Shared> SharedRideAsync(TestApi api)
    {
        var coachEmail = TestApi.NewEmail();
        (await api.RegisterAsync(coachEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(coachEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, coachEmail);
        var (athlete, athleteId) = await NewMemberAsync(api, "Athlete Luca");
        await SetProfileAsync(athlete, ftpW: null, weightKg: 70);
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        (await athlete.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        var ride = await TestApi.UploadAndWaitAsync(athlete, Fit(new FitSession(Recent(), 120, NoPower: true)));
        Assert.NotNull(ride.EstimatedAvgPowerW);
        return new Shared(coach, athlete, club, athleteId, ride.Id);
    }
}
