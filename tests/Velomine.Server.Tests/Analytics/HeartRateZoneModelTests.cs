using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// The heart-rate zones come from the threshold a rider set or a ride measured (Friel's cycling zones: 81, 90, 94 and
/// 100 %), and from the maximum otherwise (60, 70, 80 and 90 %). A beat below the model's floor is easy time, so zone
/// one starts at 0, and a coach sees the rider's own zones through the same model.
/// </summary>
public sealed class HeartRateZoneModelTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Thursday 5 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 5, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task<HttpResponseMessage> SetAsync(HttpClient client, string kind, int bpm) =>
        client.PutAsJsonAsync($"/api/v1/accounts/me/heart-rate/{kind}", new SetHeartRateRequest(bpm), Ct);

    private static Task<RideResponse> RideAsync(HttpClient client, Guid rideId) =>
        client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{rideId}", Ct)!;

    private static IntensityResponse? IntensityAsync(TrainingResponse training) => training.Intensity;

    private static async Task<TrainingResponse> TrainingAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct))!;

    /// <summary>One sample a second: n + 1 samples span n seconds.</summary>
    private static double[] Times(int seconds) => [.. Enumerable.Range(0, seconds + 1).Select(i => (double)i)];

    /// <summary>A ready ride saved straight into the database: 1 Hz, the given heart rate.</summary>
    private static async Task<Guid> AddRideAsync(
        TestApi api,
        Guid userId,
        short?[]? heartRate,
        int seconds = 120,
        bool? hideHeartRate = null)
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
            StartTime = Now.AddDays(-1),
            MovingS = seconds,
            // The privacy snapshot reads every switch together.
            HideHeartRate = hideHeartRate,
            HidePower = hideHeartRate is null ? null : false,
            HideCadence = hideHeartRate is null ? null : false,
            HideSpeed = hideHeartRate is null ? null : false,
            HideElevation = hideHeartRate is null ? null : false,
            HideTemperature = hideHeartRate is null ? null : false,
        };
        ride.Streams = new RideStreams
        {
            RideId = ride.Id,
            Time = Times(seconds),
            HeartRate = heartRate ?? Samples(seconds, 140),
        };
        db.Rides.Add(ride);
        await db.SaveChangesAsync(Ct);
        return ride.Id;
    }

    private static short?[] Samples(int seconds, short bpm) =>
        [.. Enumerable.Range(0, seconds + 1).Select(_ => (short?)bpm)];

    /// <summary>The account's numbers as a ride set them, written where a ride's measurement would leave them.</summary>
    private static async Task MeasureAsync(TestApi api, Guid userId, int? maxBpm, int? thresholdBpm, Guid? rideId = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.FirstAsync(u => u.Id == userId, Ct);
        user.MaxHeartRateBpm = maxBpm;
        user.MaxHeartRateSource = maxBpm is null ? null : HeartRateSources.Measured;
        user.MaxHeartRateRideId = maxBpm is null ? null : rideId;
        user.ThresholdHeartRateBpm = thresholdBpm;
        user.ThresholdHeartRateSource = thresholdBpm is null ? null : HeartRateSources.Measured;
        user.ThresholdHeartRateRideId = thresholdBpm is null ? null : rideId;
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseTheThreshold_WhenItWasMeasured()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 140));
        await MeasureAsync(api, member.Id, maxBpm: 185, thresholdBpm: 160, rideId);

        var ride = await RideAsync(member.Client, rideId);

        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160, HeartRateSources.Measured),
            (ride.HeartRateZoneModel, ride.HeartRateZoneReferenceBpm, ride.HeartRateZoneReferenceSource));
        var zones = ride.HeartRateZones!;
        // 81 % and 90 % of 160: zone 2 runs from 130 to 143, and zone 5 opens at the threshold itself.
        Assert.Equal((0, 129), (zones[0].From, zones[0].To));
        Assert.Equal((130, 143), (zones[1].From, zones[1].To));
        Assert.Equal(160, zones[4].From);
        Assert.Null(zones[4].To);
        Assert.Equal(120, zones[1].Seconds); // 140 bpm is 87.5 % of 160
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseTheMax_WhenTheThresholdIsOnlyEstimated()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 180)).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 115));

        var ride = await RideAsync(member.Client, rideId);

        Assert.Equal(
            (HeartRateZoneModels.Max, 180, HeartRateSources.Manual),
            (ride.HeartRateZoneModel, ride.HeartRateZoneReferenceBpm, ride.HeartRateZoneReferenceSource));
        var zones = ride.HeartRateZones!;
        // 60 % and 70 % of 180: zone 2 runs from 108 to 125, and zone 1 starts at 0.
        Assert.Equal((0, 107), (zones[0].From, zones[0].To));
        Assert.Equal((108, 125), (zones[1].From, zones[1].To));
        Assert.Equal(120, zones[1].Seconds); // 115 bpm is 63.9 % of 180
    }

    [Fact]
    public async Task Intensity_ShouldCountTheThresholdZones_WhenTheModelIsThreshold()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // Three minutes, one per band: 140 bpm is 87.5 % of 160 (zone 2, easy), 150 is 93.75 % (zone 3,
        // moderate), 160 is the threshold itself (zone 5, hard). Against a maximum of 185 the same ride would be
        // easy, hard, hard.
        short?[] heartRate = [.. Samples(119, 140), .. Samples(119, 150), .. Samples(119, 160), 160];
        var rideId = await AddRideAsync(api, member.Id, heartRate, seconds: 360);
        await MeasureAsync(api, member.Id, maxBpm: 185, thresholdBpm: 160, rideId);

        var intensity = IntensityAsync(await TrainingAsync(member.Client))!;

        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160, HeartRateSources.Measured),
            (intensity.HeartRateZoneModel, intensity.HeartRateZoneReferenceBpm, intensity.HeartRateZoneReferenceSource));
        Assert.Equal((120, 120, 120), (intensity.EasyS, intensity.ModerateS, intensity.HardS));
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseTheThreshold_WhenItWasTyped()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        (await SetAsync(member.Client, "threshold", 160)).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 140));

        var ride = await RideAsync(member.Client, rideId);

        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160, HeartRateSources.Manual),
            (ride.HeartRateZoneModel, ride.HeartRateZoneReferenceBpm, ride.HeartRateZoneReferenceSource));
        Assert.Equal((130, 143), (ride.HeartRateZones![1].From, ride.HeartRateZones[1].To));
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseTheThreshold_WhenASuggestionWasAccepted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 140));
        var suggestionId = await AddSuggestionAsync(api, member.Id, rideId, 160);

        var accepted = await member.Client.PostAsync($"/api/v1/analytics/heart-rate-suggestions/{suggestionId}/accept", null, Ct);
        accepted.EnsureSuccessStatusCode();

        var ride = await RideAsync(member.Client, rideId);
        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160, HeartRateSources.Measured),
            (ride.HeartRateZoneModel, ride.HeartRateZoneReferenceBpm, ride.HeartRateZoneReferenceSource));
        Assert.Equal((130, 143), (ride.HeartRateZones![1].From, ride.HeartRateZones[1].To));
    }

    /// <summary>An open threshold suggestion, as a ride that beat the typed number would leave it.</summary>
    private static async Task<Guid> AddSuggestionAsync(TestApi api, Guid userId, Guid rideId, int bpm)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var suggestion = new HeartRateSuggestion
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            RideId = rideId,
            Kind = HeartRateKinds.Threshold,
            Bpm = bpm,
            CreatedAt = Now,
        };
        db.HeartRateSuggestions.Add(suggestion);
        await db.SaveChangesAsync(Ct);
        return suggestion.Id;
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseTheThresholdModel_WhenACoachViewsTheRide()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        (await rider.Client.PostAsJsonAsync(
            "/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();
        (await SetAsync(rider.Client, "max", 185)).EnsureSuccessStatusCode();
        (await SetAsync(rider.Client, "threshold", 160)).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, rider.Id, Samples(120, 140));
        var path = $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}";

        var shown = await coach.Client.GetFromJsonAsync<RideResponse>(path, Ct);

        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160),
            (shown!.HeartRateZoneModel, shown.HeartRateZoneReferenceBpm));
        Assert.Equal((130, 143), (shown.HeartRateZones![1].From, shown.HeartRateZones[1].To));

        // The heart-rate privacy switch hides the zones, the model and its reference together.
        await HideHeartRateAsync(api, rideId, hidden: true);
        var hidden = await coach.Client.GetFromJsonAsync<RideResponse>(path, Ct);
        Assert.Null(hidden!.HeartRateZones);
        Assert.Null(hidden.HeartRateZoneModel);
        Assert.Null(hidden.HeartRateZoneReferenceBpm);
        Assert.Null(hidden.HeartRateZoneReferenceSource);
    }

    private static async Task HideHeartRateAsync(TestApi api, Guid rideId, bool hidden)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var ride = await db.Rides.FirstAsync(r => r.Id == rideId, Ct);
        // The privacy snapshot is read as a whole: one switch set means all of them are.
        ride.HideHeartRate = hidden;
        ride.HidePower = false;
        ride.HideCadence = false;
        ride.HideSpeed = false;
        ride.HideElevation = false;
        ride.HideTemperature = false;
        ride.TrimStartM = 0;
        ride.TrimEndM = 0;
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task HeartRateZones_ShouldCountBelowTheFloorAsEasy_WhenTheRideIsEasy()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // 100 bpm is 62.5 % of a threshold of 160: under Friel's 68 % floor, which now counts as easy time.
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 100));
        await MeasureAsync(api, member.Id, maxBpm: 185, thresholdBpm: 160, rideId);

        var ride = await RideAsync(member.Client, rideId);

        Assert.Equal((0, 129, 120.0), (ride.HeartRateZones![0].From, ride.HeartRateZones[0].To, ride.HeartRateZones[0].Seconds));
        Assert.Equal(120, IntensityAsync(await TrainingAsync(member.Client))!.EasyS);
    }

    [Fact]
    public async Task HeartRateZones_ShouldFollowTheThreshold_WhenTheTypedMaximumIsBelowIt()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        (await SetAsync(member.Client, "threshold", 160)).EnsureSuccessStatusCode();
        // A maximum lowered below the threshold afterwards is allowed: the threshold model then ignores it.
        (await SetAsync(member.Client, "max", 150)).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, member.Id, Samples(120, 155));

        var ride = await RideAsync(member.Client, rideId);

        Assert.Equal(
            (HeartRateZoneModels.Threshold, 160),
            (ride.HeartRateZoneModel, ride.HeartRateZoneReferenceBpm));
        // 155 bpm is 96.9 % of 160: zone 4, which runs from 150 to 159.
        Assert.Equal((150, 159), (ride.HeartRateZones![3].From, ride.HeartRateZones[3].To));
        Assert.Equal(120, ride.HeartRateZones[3].Seconds);
    }
}
