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
using Member = Velomine.Server.Tests.TestMember;

namespace Velomine.Server.Tests.Analytics;

public sealed class IntensityTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task<Member> NewMemberAsync(TestApi api) => api.NewMemberAsync();

    /// <summary>Puts the profile back to two known references. A null value would keep the stored one.</summary>
    private static async Task SetProfileAsync(HttpClient client, int? ftpW = null, int? birthYear = null)
    {
        foreach (var (ftp, birth) in new[] { (200, 1996), (ftpW, birthYear) })
        {
            (await client.PutAsJsonAsync(
                "/api/v1/accounts/me/profile",
                new UpdateProfileRequest("Rider", ftp, null, birth, null, "monday"),
                Ct)).EnsureSuccessStatusCode();
        }
    }

    /// <summary>A ready ride saved straight into the database: a 2-minute ride, 1 Hz, with the given signals.</summary>
    private static async Task AddRideAsync(
        TestApi api,
        Guid userId,
        short?[]? power = null,
        short?[]? heartRate = null,
        int seconds = 120,
        string startUtc = "2026-11-03T07:00:00",
        bool? hidePower = null,
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
            StartTime = DateTimeOffset.Parse(startUtc + "Z"),
            MovingS = seconds,
            HidePower = hidePower,
            HideHeartRate = hideHeartRate,
        };
        ride.Streams = new RideStreams
        {
            RideId = ride.Id,
            Time = Times(seconds),
            Power = power,
            HeartRate = heartRate,
        };
        db.Rides.Add(ride);
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>One sample a second: n + 1 samples span n seconds.</summary>
    private static double[] Times(int seconds) => [.. Enumerable.Range(0, seconds + 1).Select(i => (double)i)];

    private static short?[] Samples(int seconds, short? value) =>
        [.. Enumerable.Range(0, seconds + 1).Select(_ => value)];

    private static async Task<IntensityResponse?> IntensityAsync(HttpClient client, int days = 7) =>
        (await client.GetFromJsonAsync<TrainingResponse>($"/api/v1/analytics/training?days={days}", Ct))!.Intensity;

    /// <summary>The known values of the story, from Domestique's tests checked against intervals.icu.</summary>
    private static readonly (string Test, double Easy, double Moderate, double Hard, double? Index, string Label)[] KnownValues =
    [
        ("58Easy11Moderate31Hard", 58.0, 10.7, 31.3, 2.23, Labels.Polarised),
        ("80Easy5Moderate15Hard", 80.0, 5.0, 15.0, 2.38, Labels.Base),
        ("99Easy0Moderate0Hard", 99.9, 0.1, 0.0, null, Labels.Base),
        ("15Easy49Moderate36Hard", 15.0, 49.2, 35.8, 1.04, Labels.Pyramidal),
        ("58Easy28Moderate14Hard", 58.3, 27.6, 14.1, 1.47, Labels.Pyramidal),
        ("30Easy60Moderate10Hard", 30.0, 60.0, 10.0, 0.70, Labels.Threshold),
        ("10Easy30Moderate60Hard", 10.0, 30.0, 60.0, 1.30, Labels.Hiit),
        ("50Easy25Moderate25Hard", 50.0, 25.0, 25.0, 1.70, Labels.Mixed),
        ("70Easy20Moderate10Hard", 70.0, 20.0, 10.0, 1.54, Labels.Base),
    ];

    public static TheoryData<string> KnownValueNames => [.. KnownValues.Select(v => v.Test)];

    [Theory]
    [MemberData(nameof(KnownValueNames))]
    public void IntensityLabel_ShouldFollowTheKnownValues_WhenGivenSharesOfEachZone(string known)
    {
        var (_, easy, moderate, hard, index, label) = KnownValues.Single(v => v.Test == known);

        Assert.Equal(index, Intensity.PolarisationIndex(easy, moderate, hard));
        Assert.Equal(label, Intensity.Label(easy, moderate, hard));
    }

    [Fact]
    public async Task Intensity_ShouldHaveNoIndex_WhenThereIsNoHardTime()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = member.Id;
        await SetProfileAsync(member.Client, ftpW: 200);
        // 300 W over an FTP of 200 is 150 %: zone 7, hard. No easy or moderate time at all.
        await AddRideAsync(api, id, power: Samples(120, 300));

        var intensity = await IntensityAsync(member.Client);

        Assert.NotNull(intensity);
        Assert.Equal(100, intensity.HardPct);
        Assert.Equal(120, intensity.HardS);
        Assert.Null(intensity.PolarisationIndex); // no easy time to balance the hard
        Assert.Equal(Labels.Hiit, intensity.Label); // hard above 40 and easy under 20
        Assert.Equal(1, intensity.Rides);
    }

    [Fact]
    public async Task Intensity_ShouldUseHeartRate_WhenTheRideHasNoPower()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = member.Id;
        await SetProfileAsync(member.Client, birthYear: 1996); // maximum heart rate 187 bpm
        // 150 bpm is 80 % of 187: zone 4, moderate.
        await AddRideAsync(api, id, heartRate: Samples(120, 150));

        var intensity = await IntensityAsync(member.Client);

        Assert.NotNull(intensity);
        Assert.Equal(0, intensity!.EasyS);
        Assert.Equal(120, intensity.ModerateS);
        Assert.Equal(0, intensity.HardS);
        Assert.Equal(100, intensity.ModeratePct);
    }

    [Fact]
    public async Task Intensity_ShouldSkipTheRide_WhenItHasNeitherSignal()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = member.Id;
        await SetProfileAsync(member.Client, ftpW: 200, birthYear: 1996);
        await AddRideAsync(api, id);

        var intensity = await IntensityAsync(member.Client);

        Assert.Null(intensity);
    }

    [Fact]
    public async Task Intensity_ShouldSplitTheRangeIntoWeeks_WhenRidesFallInTwoWeeks()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var id = member.Id;
        await SetProfileAsync(member.Client, ftpW: 200);
        // Two minutes at 112 % of FTP: zone 5, hard; three minutes at 80 %: zone 3, moderate.
        await AddRideAsync(api, id, power: Samples(120, 224), startUtc: "2026-10-27T07:00:00");
        await AddRideAsync(api, id, power: Samples(180, 160), seconds: 180, startUtc: "2026-11-03T07:00:00");

        var training = (await member.Client.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=14", Ct))!;

        Assert.Equal(
            [new DateOnly(2026, 10, 26), new DateOnly(2026, 11, 2)],
            training.IntensityWeeks.Select(w => w.WeekStart));
        Assert.Equal([0, 180], training.IntensityWeeks.Select(w => w.ModerateS));
        Assert.Equal([120, 0], training.IntensityWeeks.Select(w => w.HardS));
        Assert.Equal(180, training.Intensity!.ModerateS);
        Assert.Equal(120, training.Intensity.HardS);
        Assert.Equal(2, training.Intensity.Rides);
    }

    [Fact]
    public async Task GetTraining_ShouldShowOnlyMyIntensity_WhenAnotherMemberHasRides()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        await SetProfileAsync(other.Client, ftpW: 200);
        await AddRideAsync(api, other.Id, power: Samples(120, 300));

        Assert.Null(await IntensityAsync(member.Client));
        Assert.Equal(120, (await IntensityAsync(other.Client))!.HardS);
    }

    /// <summary>A club whose owner coaches, with a rider who shares rides and training and rode 150 W.</summary>
    private static async Task<(Member Owner, AdminClubResponse Club, Member Rider)> SharedClubAsync(TestApi api, int ftpW = 200)
    {
        var owner = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, owner);
        var rider = await NewMemberAsync(api);
        (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new Velomine.Server.Features.Sharing.UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();
        await SetProfileAsync(rider.Client, ftpW: ftpW, birthYear: 1996);
        return (owner, club, rider);
    }

    [Fact]
    public async Task CoachTraining_ShouldFallBackToHeartRate_WhenPowerIsHidden()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        // 300 W over an FTP of 200 is hard; heart rate 150 of 187 is moderate. The hidden power is never read.
        await AddRideAsync(api, rider.Id, power: Samples(120, 300), heartRate: Samples(120, 150), hidePower: true);

        var training = await owner.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.NotNull(training!.Intensity);
        Assert.Equal(0, training.Intensity.HardS);
        Assert.Equal(120, training.Intensity.ModerateS);
    }

    [Fact]
    public async Task CoachTraining_ShouldSkipTheRide_WhenBothSignalsAreHidden()
    {
        await using var api = await StartAsync();
        var (owner, club, rider) = await SharedClubAsync(api);
        await AddRideAsync(api, rider.Id, power: Samples(120, 300), heartRate: Samples(120, 150),
            hidePower: true, hideHeartRate: true);

        var training = await owner.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Null(training!.Intensity);
        Assert.Empty(training.IntensityWeeks);
    }

    [Fact]
    public async Task CoachTraining_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var (_, club, rider) = await SharedClubAsync(api);
        await AddRideAsync(api, rider.Id, power: Samples(120, 300), heartRate: Samples(120, 150), hidePower: true);
        var stranger = await NewMemberAsync(api);
        _ = await TestClubs.CreateAsync(api, stranger);

        var response = await stranger.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
