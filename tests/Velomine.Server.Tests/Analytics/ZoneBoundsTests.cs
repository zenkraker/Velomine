using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
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
/// A rider can move the top of every zone by hand: the bounds are fractions of the FTP or of the heart rate, so they
/// follow it, they are refused unless strictly rising, between 0.30 and 2.00 and of two decimals, and they apply
/// wherever zones are computed on request. TRIMP is stored at read, so it keeps the standard bounds.
/// </summary>
public sealed class ZoneBoundsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Thursday 5 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 5, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task<HttpResponseMessage> SetZonesAsync(HttpClient client, string set, double[] bounds) =>
        client.PutAsJsonAsync($"/api/v1/accounts/me/zones/{set}", new SetZonesRequest(bounds), Ct);

    private static Task<ZonesResponse> ZonesAsync(HttpClient client) =>
        client.GetFromJsonAsync<ZonesResponse>("/api/v1/accounts/me/zones", Ct)!;

    private static ZoneSetResponse? Set(ZonesResponse zones, string set) =>
        zones.Sets.FirstOrDefault(s => s.Set == set);

    private static Task<RideResponse> RideAsync(HttpClient client, Guid rideId) =>
        client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{rideId}", Ct)!;

    private static async Task<TrainingResponse> TrainingAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct))!;

    /// <summary>One sample a second: n + 1 samples span n seconds.</summary>
    private static double[] Times(int seconds) => [.. Enumerable.Range(0, seconds + 1).Select(i => (double)i)];

    private static short?[] Samples(int seconds, short value) =>
        [.. Enumerable.Range(0, seconds + 1).Select(_ => (short?)value)];

    /// <summary>A ready ride saved straight into the database: 1 Hz, one heart rate and one power for every second.</summary>
    private static async Task<Guid> AddRideAsync(
        TestApi api,
        Guid userId,
        short?[]? heartRate = null,
        short?[]? power = null,
        int seconds = 120,
        double? trimp = null)
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
            Trimp = trimp,
        };
        ride.Streams = new RideStreams
        {
            RideId = ride.Id,
            Time = Times(seconds),
            HeartRate = heartRate,
            Power = power,
        };
        db.Rides.Add(ride);
        await db.SaveChangesAsync(Ct);
        return ride.Id;
    }

    [Fact]
    public async Task SetZones_ShouldMoveTheZones_WhenBoundsAreValid()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct))
            .EnsureSuccessStatusCode();

        var saved = await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70]);

        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var power = Set(await ZonesAsync(member.Client), ZoneSets.Power)!;
        Assert.True(power.Custom);
        Assert.Equal(250, power.Reference);
        // 60 % of 250 is 150: zone 1 runs up to 149 W, and zone 2 starts there.
        Assert.Equal((0, 149), (power.Zones[0].From, power.Zones[0].To));
        Assert.Equal(150, power.Zones[1].From);
    }

    [Fact]
    public async Task Zones_ShouldFollowTheFtp_WhenCustomBoundsExist()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct))
            .EnsureSuccessStatusCode();
        (await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70])).EnsureSuccessStatusCode();

        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(300), Ct))
            .EnsureSuccessStatusCode();

        var power = Set(await ZonesAsync(member.Client), ZoneSets.Power)!;
        // 60 % of 300 is 180: zone 1 runs up to 179 W with the same fractions.
        Assert.Equal((0.60, 300, 0, 179), (power.Bounds[0], power.Reference, power.Zones[0].From, power.Zones[0].To));
    }

    [Fact]
    public async Task ResetZones_ShouldGoBackToAutomatic_WhenCalled()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct))
            .EnsureSuccessStatusCode();
        (await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70])).EnsureSuccessStatusCode();

        var reset = await member.Client.DeleteAsync($"/api/v1/accounts/me/zones/{ZoneSets.Power}", Ct);

        Assert.Equal(HttpStatusCode.OK, reset.StatusCode);
        var cleared = await reset.Content.ReadFromJsonAsync<ZonesResponse>(Ct);
        var power = Set(cleared!, ZoneSets.Power)!;
        Assert.False(power.Custom);
        Assert.Equal(TrainingLoad.PowerBounds, power.Bounds);
        Assert.Equal((0, 137), (power.Zones[0].From, power.Zones[0].To));
    }

    [Fact]
    public async Task SetZones_ShouldRefuse_WhenBoundsAreNotRising()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var refused = await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.60, 0.90, 1.05, 1.20, 1.50]);

        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
    }

    [Fact]
    public async Task SetZones_ShouldRefuse_WhenABoundHasThreeDecimals()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var refused = await SetZonesAsync(member.Client, ZoneSets.Power, [0.555, 0.75, 0.90, 1.05, 1.20, 1.50]);

        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
    }

    [Fact]
    public async Task SetZones_ShouldRefuse_WhenBoundsAreOutOfRange()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var tooHigh = await SetZonesAsync(member.Client, ZoneSets.Power, [0.55, 0.75, 0.90, 1.05, 1.20, 2.01]);
        var tooLow = await SetZonesAsync(member.Client, ZoneSets.Power, [0.29, 0.75, 0.90, 1.05, 1.20, 1.50]);

        Assert.Equal(HttpStatusCode.BadRequest, tooHigh.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, tooLow.StatusCode);
    }

    [Fact]
    public async Task SetZones_ShouldRefuse_WhenTheCountIsWrong()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        // Four bounds belong to a heart-rate set; power takes six.
        var refused = await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20]);
        var heartRate = await SetZonesAsync(member.Client, ZoneSets.HeartRateMax, [0.60, 0.70, 0.80, 0.90]);

        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
        Assert.Equal(HttpStatusCode.OK, heartRate.StatusCode);
    }

    [Fact]
    public async Task SetZones_ShouldReturn404_WhenTheSetIsUnknown()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var put = await SetZonesAsync(member.Client, "heart-rate", [0.60, 0.70, 0.80, 0.90]);
        var delete = await member.Client.DeleteAsync("/api/v1/accounts/me/zones/speed", Ct);

        Assert.Equal(HttpStatusCode.NotFound, put.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, delete.StatusCode);
    }

    [Fact]
    public async Task RideZones_ShouldUseCustomBounds_WhenTheRiderSetThem()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct))
            .EnsureSuccessStatusCode();
        (await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70])).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, member.Id, power: Samples(120, 200));

        var ride = await RideAsync(member.Client, rideId);

        // 200 W against the custom bounds is zone 2, which runs from 150 to 224 W; the standard zone 2 ends at 187.
        var zones = ride.PowerZones!;
        Assert.Equal((0, 149), (zones[0].From, zones[0].To));
        Assert.Equal((150, 224), (zones[1].From, zones[1].To));
        Assert.Equal(120, zones[1].Seconds);
    }

    [Fact]
    public async Task Intensity_ShouldUseCustomBounds_WhenTheRiderSetThem()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct))
            .EnsureSuccessStatusCode();
        await AddRideAsync(api, member.Id, power: Samples(120, 200));

        // 200 W is 80 % of the FTP: moderate against the standard bounds (easy ends at 75 %), easy against these.
        var standard = (await TrainingAsync(member.Client)).Intensity!;
        (await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70])).EnsureSuccessStatusCode();
        var custom = (await TrainingAsync(member.Client)).Intensity!;

        Assert.Equal((0, 120), (standard.EasyS, standard.ModerateS));
        Assert.Equal((120, 0), (custom.EasyS, custom.ModerateS));
    }

    [Fact]
    public async Task RideTrimp_ShouldKeepTheStandardBounds_WhenCustomBoundsExist()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/heart-rate/max", new SetHeartRateRequest(200), Ct))
            .EnsureSuccessStatusCode();
        // 130 bpm is 65 % of the maximum: zone 2 with the standard bounds, zone 3 with these.
        (await SetZonesAsync(member.Client, ZoneSets.HeartRateMax, [0.50, 0.60, 0.70, 0.80])).EnsureSuccessStatusCode();
        // Trimp is null, so the ride's detail works the older score out on request, the way it does for an old ride.
        var rideId = await AddRideAsync(api, member.Id, heartRate: Samples(120, 130));

        var ride = await RideAsync(member.Client, rideId);

        // 120 s in zone 2 at one point a minute: 4.0, not the 6.0 the custom bounds would give. The chart itself
        // follows the custom bounds.
        Assert.Equal(4.0, ride.Trimp);
        Assert.Equal((100, 119), (ride.HeartRateZones![1].From, ride.HeartRateZones[1].To));
    }

    [Fact]
    public async Task HeartRateZones_ShouldUseCustomThresholdBounds_WhenACoachViewsTheRide()
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
        (await rider.Client.PutAsJsonAsync("/api/v1/accounts/me/heart-rate/max", new SetHeartRateRequest(185), Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync("/api/v1/accounts/me/heart-rate/threshold", new SetHeartRateRequest(160), Ct))
            .EnsureSuccessStatusCode();
        (await SetZonesAsync(rider.Client, ZoneSets.HeartRateThreshold, [0.70, 0.80, 0.90, 1.00])).EnsureSuccessStatusCode();
        var rideId = await AddRideAsync(api, rider.Id, heartRate: Samples(120, 140));

        var shown = await coach.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/rides/{rideId}", Ct);

        Assert.Equal((HeartRateZoneModels.Threshold, 160), (shown!.HeartRateZoneModel, shown.HeartRateZoneReferenceBpm));
        // 70 % and 80 % of 160: zone 2 runs from 112 to 127, and 140 bpm lands in zone 3.
        Assert.Equal((0, 111), (shown.HeartRateZones![0].From, shown.HeartRateZones[0].To));
        Assert.Equal((112, 127), (shown.HeartRateZones[1].From, shown.HeartRateZones[1].To));
        Assert.Equal(120, shown.HeartRateZones[2].Seconds);
    }

    [Fact]
    public async Task AccountExport_ShouldCarryTheZoneBounds_WhenTheRiderSetThem()
    {
        // A clock near the real one: a data-protection token's own expiry uses the system clock.
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new OffsetTime(DateTimeOffset.UtcNow)));
        });
        var member = await api.NewMemberAsync();
        (await SetZonesAsync(member.Client, ZoneSets.Power, [0.60, 0.90, 1.05, 1.20, 1.40, 1.70])).EnsureSuccessStatusCode();

        var requested = await member.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var stream = zip.GetEntry("profile.json")!.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var bounds = document.RootElement.GetProperty("zoneBounds");
        Assert.Equal(
            [0.60, 0.90, 1.05, 1.20, 1.40, 1.70],
            bounds.GetProperty("power").EnumerateArray().Select(v => v.GetDouble()).ToArray());
        Assert.Equal(JsonValueKind.Null, bounds.GetProperty("heartRateMax").ValueKind);
        Assert.Equal(JsonValueKind.Null, bounds.GetProperty("heartRateThreshold").ValueKind);
    }
}
