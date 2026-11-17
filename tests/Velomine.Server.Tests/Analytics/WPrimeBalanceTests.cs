using System.Net;
using System.Net.Http.Json;
using Dynastream.Fit;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// How much W′ is left through a ride (Skiba et al. 2015, differential form), from the rider's current fit: 2, 5, 10
/// and 20 minute bests over the last 90 days.
/// </summary>
public sealed class WPrimeBalanceTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static readonly DateTimeOffset Now = new(2026, 11, 17, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    /// <summary>
    /// A ready ride of bests that follow the model P(t) = CP + W′ / t for CP 250 W and W′ 20,000 J, to the watt:
    /// 417, 317, 283 and 267 W. A stored best is its longest stretch, so a longer ride of the same power changes nothing.
    /// </summary>
    private static async Task AddFitAsync(TestApi api, Guid userId) =>
        await AddBestsAsync(api, userId, (120, 417), (300, 317), (600, 283), (1200, 267));

    [Fact]
    public void WPrimeBalance_ShouldKeepOneBalancePerSample_WhenSamplesAreThreeSecondsApart()
    {
        var streams = GappedStreams(5, stepS: 3, watts: 350);

        var balance = WPrimeBalance.ForRide(streams, Fit);

        Assert.NotNull(balance);
        Assert.Equal(streams.Time.Length, balance.PerSample.Length);
        // 350 W for the 12 s of the 3 s stretches is 1,200 J above CP. Each sample holds the balance its stretch
        // ended on: one value per sample, never two samples late, and the balances step with time.
        Assert.Equal<int?>([19_700, 19_400, 19_100, 18_800, 18_800], balance.PerSample);
        Assert.InRange(balance.MinJ!.Value, 18_800, 18_900);
    }

    [Fact]
    public void WPrimeBalance_ShouldKeepOneBalancePerSample_WhenSamplesAreFiveSecondsApart()
    {
        var streams = GappedStreams(7, stepS: 5, watts: 350);

        var balance = WPrimeBalance.ForRide(streams, Fit);

        Assert.NotNull(balance);
        Assert.Equal(streams.Time.Length, balance.PerSample.Length);
        // 5 stretches of 5 s at 350 W is 2,500 J above CP, and the balance is the ride ending on its last sample.
        Assert.InRange(balance.MinJ!.Value, 16_900, 17_100);
        Assert.InRange((int)balance.PerSample[^1]!, 16_900, 17_100);
    }

    [Fact]
    public void WPrimeBalance_ShouldEndAtFourteenThousand_WhenSixtySecondsAreRiddenAtOneHertz()
    {
        // The steady 1 Hz maths must not move: 60 s at 350 W against CP 250 and W′ 20,000 ends at 14,000 J. A sample
        // shows its stretch's balance after the seconds up to it, so the 60th second's reading is on sample 59.
        var balance = WPrimeBalance.ForRide(GappedStreams(61, stepS: 1, watts: 350), Fit);

        Assert.NotNull(balance);
        Assert.Equal(61, balance.PerSample.Length);
        Assert.InRange((int)balance.PerSample[^1]!, 13_900, 14_100);
    }

    /// <summary>Streams of samples <paramref name="stepS"/> apart, each holding the same power.</summary>
    private static RideStreams GappedStreams(int count, int stepS, short watts) => new()
    {
        RideId = Guid.NewGuid(),
        Time = [.. Enumerable.Range(0, count).Select(i => (double)(i * stepS))],
        Power = [.. Enumerable.Repeat<short?>(watts, count)],
    };

    [Fact]
    public async Task GetRideStreams_ShouldReturnEverySample_WhenSamplesAreGapped()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddFitAsync(api, member.Id);
        (await SetFtpAsync(member.Client, 250)).EnsureSuccessStatusCode();
        var ride = await TestApi.UploadAndWaitAsync(member.Client, RideFile(Now.AddMinutes(-30), 120, 350, recordEveryS: 3));

        var response = await member.Client.GetAsync($"/api/v1/rides/{ride.Id}/streams", Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var streams = await response.Content.ReadFromJsonAsync<RideStreamsResponse>(Ct);
        Assert.Equal(streams!.Time.Length, streams.WPrimeBalanceJ!.Length);
    }

    /// <summary>Critical power and W′ as the story writes them: CP 250 W, W′ 20,000 J.</summary>
    private static readonly CriticalPowerEstimate Fit = new(250, 20_000, null, 1, [120, 300, 600, 1200]);

    private static async Task AddBestsAsync(TestApi api, Guid userId, params (int Seconds, int Watts)[] bests)
    {
        var rideId = Guid.NewGuid();
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride { Id = rideId, UserId = userId, Status = RideStatus.Ready, StartTime = Now.AddDays(-1) });
        foreach (var (seconds, watts) in bests)
            db.RidePowerBests.Add(new RidePowerBest { RideId = rideId, DurationS = seconds, Watts = watts });
        await db.SaveChangesAsync(Ct);
    }

    private static Task<HttpResponseMessage> SetFtpAsync(HttpClient client, int watts) =>
        client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(watts), Ct);

    /// <summary>A FIT file at one power every <paramref name="recordEveryS"/> seconds, paused from <paramref name="pauseAtS"/> for <paramref name="pauseS"/>.</summary>
    private static byte[] RideFile(DateTimeOffset start, int seconds, int watts, int? pauseAtS = null, int pauseS = 0, int recordEveryS = 1)
    {
        using var stream = new MemoryStream();
        var encode = new Encode(ProtocolVersion.V20);
        encode.Open(stream);

        var fileId = new FileIdMesg();
        fileId.SetType(Dynastream.Fit.File.Activity);
        fileId.SetManufacturer(Manufacturer.Garmin);
        fileId.SetProduct(1);
        fileId.SetSerialNumber(1234);
        encode.Write(fileId);

        var timer = new EventMesg();
        timer.SetTimestamp(new Dynastream.Fit.DateTime(start.UtcDateTime));
        timer.SetEvent(Dynastream.Fit.Event.Timer);
        timer.SetEventType(EventType.Start);
        timer.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(timer);

        var elapsed = 0;
        for (var s = 0; s < seconds; s++)
        {
            if (pauseAtS is { } at && s == at && pauseS > 0)
            {
                var stop = new EventMesg();
                stop.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(s).UtcDateTime));
                stop.SetEvent(Dynastream.Fit.Event.Timer);
                stop.SetEventType(EventType.StopAll);
                stop.SetTimerTrigger((byte)TimerTrigger.Manual);
                encode.Write(stop);
                s += pauseS - 1;
                elapsed += pauseS;
                var resume = new EventMesg();
                resume.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(s + 1).UtcDateTime));
                resume.SetEvent(Dynastream.Fit.Event.Timer);
                resume.SetEventType(EventType.Start);
                resume.SetTimerTrigger((byte)TimerTrigger.Manual);
                encode.Write(resume);
                continue;
            }

            if (s % recordEveryS != 0) continue;

            var record = new RecordMesg();
            record.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(s).UtcDateTime));
            record.SetPositionLat((int)(46.0 * (2147483648.0 / 180.0)));
            record.SetPositionLong((int)(11.0 * (2147483648.0 / 180.0)));
            record.SetAltitude(300f);
            record.SetSpeed(8);
            record.SetDistance(elapsed * 8f);
            record.SetHeartRate(150);
            record.SetPower((ushort)watts);
            record.SetCadence(90);
            encode.Write(record);
            elapsed++;
        }

        var end = start.AddSeconds(elapsed).UtcDateTime;
        var done = new EventMesg();
        done.SetTimestamp(new Dynastream.Fit.DateTime(end));
        done.SetEvent(Dynastream.Fit.Event.Timer);
        done.SetEventType(EventType.StopAll);
        done.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(done);

        var summary = new SessionMesg();
        summary.SetTimestamp(new Dynastream.Fit.DateTime(end));
        summary.SetStartTime(new Dynastream.Fit.DateTime(start.UtcDateTime));
        summary.SetTotalElapsedTime(elapsed);
        summary.SetTotalTimerTime(elapsed);
        summary.SetSport(Sport.Cycling);
        encode.Write(summary);

        var activity = new ActivityMesg();
        activity.SetTimestamp(new Dynastream.Fit.DateTime(end));
        activity.SetLocalTimestamp(new Dynastream.Fit.DateTime(end.AddHours(2)).GetTimeStamp());
        activity.SetNumSessions(1);
        encode.Write(activity);

        encode.Close();
        return stream.ToArray();
    }

    /// <summary>The story's whole-minute ride: 350 W for 120 s, so its balance after that minute is 14,000 J.</summary>
    private static Task<RideResponse> MinuteRideAsync(HttpClient client) =>
        TestApi.UploadAndWaitAsync(client, RideFile(Now.AddMinutes(-30), 120, 350));

    /// <summary>A member with the fit above and one ride of the given power. The fit comes from stored bests, not rides.</summary>
    private static async Task<(TestMember Member, RideResponse Ride)> RiderWithRideAsync(
        TestApi api, int seconds, int watts, int? pauseAtS = null, int pauseS = 0)
    {
        var member = await api.NewMemberAsync();
        await AddFitAsync(api, member.Id);
        (await SetFtpAsync(member.Client, 250)).EnsureSuccessStatusCode();
        return (member, await TestApi.UploadAndWaitAsync(
            member.Client, RideFile(Now.AddMinutes(-30), seconds, watts, pauseAtS, pauseS)));
    }

    private static async Task<int?> WPrimeAsync(HttpClient client, Guid rideId) =>
        (await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{rideId}", Ct))!.WPrimeJ;

    [Fact]
    public void WPrimeBalance_ShouldDropByTheWorkAboveCp_WhenRidingAboveCp()
    {
        var balance = WPrimeBalance.Series([.. Enumerable.Repeat(350d, 60)], Fit);

        Assert.Equal(14_000, balance[^1], 6);
        Assert.Equal(19_900, balance[0], 6);
    }

    [Fact]
    public void WPrimeBalance_ShouldRecoverTowardsWPrime_WhenRidingBelowCp()
    {
        var balance = WPrimeBalance.Series([.. Enumerable.Repeat(350d, 60), 150d], Fit);

        // 14,000 + (20,000 − 14,000) × (250 − 150) / 20,000 = 14,030
        Assert.Equal(14_030, balance[^1], 6);
    }

    [Fact]
    public void WPrimeBalance_ShouldNeverExceedWPrime_WhenRidingEasyFromTheStart()
    {
        var balance = WPrimeBalance.Series([.. Enumerable.Repeat(100d, 600)], Fit);
        Assert.All(balance, b => Assert.Equal(20_000, b, 6));
    }

    [Fact]
    public void WPrimeBalance_ShouldGoBelowZero_WhenTheRiderBeatsTheModel()
    {
        var balance = WPrimeBalance.Series([.. Enumerable.Repeat(400d, 200)], Fit);
        Assert.Equal(-10_000, balance[^1], 6);
    }

    [Fact]
    public async Task WPrimeBalance_ShouldDropByTheWorkAboveCp_WhenTheRideIsRead()
    {
        await using var api = await StartAsync();
        var (member, ride) = await RiderWithRideAsync(api, seconds: 120, watts: 350);

        Assert.InRange((await WPrimeAsync(member.Client, ride.Id))!.Value, 20_000, 20_100);
        var streams = await member.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{ride.Id}/streams", Ct);
        // Each sample holds the balance its stretch reached, in whole joules: the work above critical power comes off
        // one second at a time, and the balance is worked out after a full minute of it.
        Assert.InRange(streams!.WPrimeBalanceJ![0], 19_900, 20_000);
        Assert.InRange(streams.WPrimeBalanceJ[1], 19_800, 19_900);
        Assert.InRange(streams.WPrimeBalanceJ[60], 13_900, 14_100);
    }

    [Fact]
    public async Task WPrimeBalance_ShouldCarryOverAPause_WhenTheRideIsPaused()
    {
        await using var api = await StartAsync();
        // 350 W, stopped for 45 s after half a minute: 100 J a second comes off, and a stop recovers nothing.
        var (member, ride) = await RiderWithRideAsync(api, seconds: 120, watts: 350, pauseAtS: 30, pauseS: 45);

        var streams = await member.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{ride.Id}/streams", Ct);

        // The stop carries the balance over, it does not recover it: after 45 s stopped the ride goes back down from
        // where it was, 7,000 J below the start, where riding easy would have brought it all back.
        Assert.InRange(streams!.WPrimeBalanceJ![1], 19_800, 19_900);
        Assert.InRange(streams.WPrimeBalanceJ[^1], 12_600, 12_800);
    }

    [Fact]
    public async Task WPrimeBalance_ShouldBeNull_WhenTheRiderHasNoFit()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await TestApi.UploadAndWaitAsync(member.Client, RideFile(Now.AddHours(-3), 120, 350));

        var streams = await member.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{ride.Id}/streams", Ct);

        Assert.Null(streams!.WPrimeBalanceJ);
        Assert.Null((await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.MinWPrimeBalanceJ);
        Assert.Null((await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.WPrimeJ);
    }

    [Fact]
    public async Task WPrimeBalance_ShouldNotBeVisible_WhenTheRideBelongsToAnotherMember()
    {
        await using var api = await StartAsync();
        var (_, ride) = await RiderWithRideAsync(api, seconds: 120, watts: 350);
        var stranger = await api.NewMemberAsync("Someone Else");

        Assert.Equal(HttpStatusCode.NotFound, (await stranger.Client.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await stranger.Client.GetAsync($"/api/v1/rides/{ride.Id}/streams", Ct)).StatusCode);
    }

    /// <summary>A club with a coach and an athlete in it, both signed in, with the athlete sharing what the test says.</summary>
    private static async Task<(HttpClient Coach, Guid ClubId, TestMember Athlete)> ClubAsync(
        TestApi api, string analytics, string rides = "coaches")
    {
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(ownerEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, ownerEmail);
        var athlete = await api.NewMemberAsync("Athlete Luca");
        (await athlete.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        (await athlete.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = rides, Analytics = analytics, Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        return (coach, club.Id, athlete);
    }

    [Fact]
    public async Task CoachRide_ShouldShowWPrimeBalance_WhenAnalyticsIsShared()
    {
        await using var api = await StartAsync();
        var (coach, clubId, athlete) = await ClubAsync(api, analytics: "coaches");
        await AddFitAsync(api, athlete.Id);
        var ride = await MinuteRideAsync(athlete.Client);

        var shared = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        var streams = await coach.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);

        // The minute at 350 W ends at 14,000 J, and the last reading a second later is what the ride ended on.
        Assert.InRange(shared!.MinWPrimeBalanceJ!.Value, 8_000, 14_100);
        Assert.InRange(shared.WPrimeJ!.Value, 20_000, 20_040);
        Assert.Equal(shared.MinWPrimeBalanceJ, streams!.WPrimeBalanceJ![^1]);
    }

    [Fact]
    public async Task CoachRide_ShouldHideWPrimeBalance_WhenPowerIsHidden()
    {
        await using var api = await StartAsync();
        var (coach, clubId, athlete) = await ClubAsync(api, analytics: "coaches");
        await AddFitAsync(api, athlete.Id);
        var ride = await MinuteRideAsync(athlete.Client);

        // The privacy snapshot is copied onto a ride at import, so hiding power now reaches only new rides.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.Id == ride.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.HidePower, true), Ct);
        }

        var hidden = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        var streams = await coach.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);

        Assert.Null(hidden!.MinWPrimeBalanceJ);
        Assert.Null(hidden.WPrimeJ);
        Assert.Null(streams!.WPrimeBalanceJ);
    }

    [Fact]
    public async Task CoachRide_ShouldHideWPrimeBalance_WhenThereIsNoAnalyticsGrant()
    {
        await using var api = await StartAsync();
        var (coach, clubId, athlete) = await ClubAsync(api, analytics: "none");
        await AddFitAsync(api, athlete.Id);
        var ride = await MinuteRideAsync(athlete.Client);

        var shared = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        var streams = await coach.GetFromJsonAsync<RideStreamsResponse>(
            $"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);

        Assert.Null(shared!.MinWPrimeBalanceJ);
        Assert.Null(shared.WPrimeJ);
        Assert.Null(streams!.WPrimeBalanceJ);
    }

    [Fact]
    public async Task CoachRide_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var (_, clubId, athlete) = await ClubAsync(api, analytics: "coaches");
        var outsider = await api.NewMemberAsync("Outsider Sam");
        await AddFitAsync(api, athlete.Id);
        var ride = await MinuteRideAsync(athlete.Client);

        Assert.Equal(HttpStatusCode.NotFound,
            (await outsider.Client.GetAsync($"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await outsider.Client.GetAsync($"/api/v1/clubs/{clubId}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct)).StatusCode);
    }
}
