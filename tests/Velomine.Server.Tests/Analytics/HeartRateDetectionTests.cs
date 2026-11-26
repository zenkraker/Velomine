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
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Rides.TestRideFiles;
using SubSport = Dynastream.Fit.SubSport;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// A ride that shows a higher heart rate teaches Velomine the number, once, when the ride is first read: a number the
/// rider typed is only suggested, a number that was estimated or measured before is used. A lower one never counts.
/// One ride can move both numbers, and its notes are the rider's own.
/// </summary>
public sealed class HeartRateDetectionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow;

    /// <summary>The estimate when no age is known and no maximum is set: 89 % is the threshold, 208 the maximum's own.</summary>
    private const int MaxCandidate = 200;

    /// <summary>The export test passes a clock that follows the wall clock: its link is a two-minute data-protection token
    /// whose expiry uses the system clock, so a clock frozen at class start makes the link expired once the class has run
    /// for two minutes.</summary>
    private Task<TestApi> StartAsync(TimeProvider? clock = null) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(clock ?? new FixedTime(Now)));
    });

    private static Task<HttpResponseMessage> SetAsync(HttpClient client, string kind, int bpm) =>
        client.PutAsJsonAsync($"/api/v1/accounts/me/heart-rate/{kind}", new SetHeartRateRequest(bpm), Ct);

    private static async Task<ProfileResponse> ProfileAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!;

    /// <summary>Sets a birth year so the maximum in use is Tanaka's estimate (208 − 0.7 × age): 180 for age 40.</summary>
    private static async Task SetBirthYearAsync(HttpClient client, int birthYear) =>
        (await client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, birthYear, null, "monday"), Ct)).EnsureSuccessStatusCode();

    private static async Task<HeartRateSuggestionResponse[]> SuggestionsAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListHeartRateSuggestionsResponse>("/api/v1/analytics/heart-rate-suggestions", Ct))!
            .Suggestions;

    private static Task<RideResponse> UploadAsync(
        HttpClient client, DateTimeOffset start, Func<int, short> heartRate, int seconds = 1800) =>
        TestApi.UploadAndWaitAsync(client, Fit(Ride(start, heartRate, seconds)));

    /// <summary>A road ride rather than the generic sub-sport, so the bike and its wheel do not decide the numbers.</summary>
    private static FitSession Ride(DateTimeOffset start, Func<int, short> heartRate, int seconds) => new(
        start.UtcDateTime, seconds, SubSport: SubSport.Road, HeartRate: heartRate);

    private static Func<int, short> Flat(int bpm) => _ => (short)bpm;

    /// <summary>A ride that starts <paramref name="hoursAgo"/> ago, on the member's calendar without an offset.</summary>
    private static DateTimeOffset HoursAgo(double hours) => Now.AddHours(-hours);

    /// <summary>A hour of the day that is the same on the member's calendar whether the file says an offset or not.</summary>
    private static DateTimeOffset Yesterday => new(Now.UtcDateTime.Date.AddDays(-1).AddHours(10), TimeSpan.Zero);

    [Fact]
    public async Task MaxHeartRate_ShouldBeUsedAutomatically_WhenARideIsHigherThanTheEstimate()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // No maximum set: an estimate or nothing, so a higher ride is used at once.
        Assert.NotEqual(HeartRateSources.Manual, (await ProfileAsync(member.Client)).MaxHeartRateSource);
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((MaxCandidate, HeartRateSources.Measured), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Equal(HeartRateNotes.MaxMeasured, ride.HeartRateNote);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var row = await db.HeartRateHistory.AsNoTracking()
            .SingleAsync(h => h.UserId == member.Id && h.Kind == HeartRateKinds.Max, Ct);
        Assert.Equal((MaxCandidate, HeartRateSources.Measured, ride.Id), (row.Bpm, row.Source, row.RideId!.Value));
    }

    [Fact]
    public async Task MaxHeartRate_ShouldBeSuggested_WhenTheRiderTypedALowerOne()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));

        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Max);
        Assert.Equal((MaxCandidate, ride.Id), (suggestion.Bpm, suggestion.RideId));
        Assert.Equal(HeartRateNotes.MaxSuggested, ride.HeartRateNote);
        var profile = await ProfileAsync(member.Client);
        Assert.Equal((185, HeartRateSources.Manual), (profile.MaxHeartRate, profile.MaxHeartRateSource));
    }

    [Fact]
    public async Task MaxHeartRate_ShouldIgnoreASpike_WhenTheStrapJumps()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // An estimate of 180 from age 40: a modest 140 bpm ride is below it, so it changes nothing.
        await SetBirthYearAsync(member.Client, Now.Year - 40);

        // One second at 230 goes in the five-second median; the steady 140 never gets near the estimate.
        var ride = await UploadAsync(member.Client, Yesterday, s => (short)(s == 600 ? 230 : 140));

        Assert.Null(ride.HeartRateNote);
        Assert.NotEqual(HeartRateSources.Measured, (await ProfileAsync(member.Client)).MaxHeartRateSource);
        Assert.Empty(await SuggestionsAsync(member.Client));
    }

    [Fact]
    public async Task MaxHeartRate_ShouldIgnoreAJump_WhenItRisesTooFastBeforeThePeak()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // An estimate of 180 from age 40: the 200 bpm hold would exceed it, but the rise guard rejects the jump.
        await SetBirthYearAsync(member.Client, Now.Year - 40);

        // 140 to 200 within two seconds, then held: a heart does not get there that fast.
        var ride = await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 140 : s < 602 ? 170 : MaxCandidate));

        Assert.Null(ride.HeartRateNote);
        Assert.NotEqual(HeartRateSources.Measured, (await ProfileAsync(member.Client)).MaxHeartRateSource);
    }

    [Fact]
    public async Task ThresholdHeartRate_ShouldBeTheLastTwentyMinutes_WhenAThirtyMinuteEffortIsFound()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 150 : 165));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((165, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal(HeartRateNotes.ThresholdMeasured, ride.HeartRateNote);
    }

    [Fact]
    public async Task HeartRateDetection_ShouldUseTheMeasuredThresholdAutomatically_WhenARideBeatsIt()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A ceiling above both efforts and below them by more than the 89 % estimate (160 bpm of 180), so the first
        // ride measures the threshold and the second one beats it.
        (await SetAsync(member.Client, "max", 180)).EnsureSuccessStatusCode();
        await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 150 : 165));
        var measured = await ProfileAsync(member.Client);
        Assert.Equal((165, HeartRateSources.Measured), (measured.ThresholdHeartRate, measured.ThresholdHeartRateSource));

        // A measured number is not the rider's own: a higher effort is used, never only suggested.
        var ride = await UploadAsync(member.Client, Yesterday.AddDays(-1), s => (short)(s < 600 ? 150 : 175));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((175, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal(ride.Id, profile.ThresholdHeartRateRideId);
        Assert.Equal(HeartRateNotes.ThresholdMeasured, ride.HeartRateNote);
        Assert.DoesNotContain(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Threshold);
    }

    [Fact]
    public async Task ThresholdHeartRate_ShouldNotBeLowered_WhenARideIsEasier()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 200)).EnsureSuccessStatusCode();
        (await SetAsync(member.Client, "threshold", 165)).EnsureSuccessStatusCode();
        // The ride holds 200 for a while, so the maximum would otherwise rise; the threshold stays where it is.
        var ride = await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 140 : 158));

        Assert.Equal(165, (await ProfileAsync(member.Client)).ThresholdHeartRate);
        Assert.DoesNotContain(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Threshold);
        Assert.NotEqual(HeartRateNotes.ThresholdMeasured, ride.HeartRateNote);
        Assert.NotEqual(HeartRateNotes.ThresholdSuggested, ride.HeartRateNote);
    }

    /// <summary>An hour that earns both numbers: a maximum of 200 bpm and a threshold of 188.</summary>
    private static short BothNumbers(int s) => (short)(s < 600 ? 150 : s < 1175 ? 175 : s < 1200 ? 175 + (s - 1174) : 200);

    /// <summary>An hour with a short 200 bpm peak over a 170 bpm base: a maximum of 200 and a threshold of 171.</summary>
    private static short PeakOverBase(int s) =>
        (short)(s < 600 ? 150 : s < 1300 ? 170 : s < 1330 ? 170 + (s - 1299) : s < 1360 ? 200 : 170);

    [Fact]
    public async Task HeartRateDetection_ShouldUpdateBoth_WhenARideRaisesTheMaxAndHoldsAThresholdEffort()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await UploadAsync(member.Client, Yesterday, BothNumbers);

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((200, HeartRateSources.Measured), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Equal((188, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal((ride.Id, ride.Id), (profile.MaxHeartRateRideId, profile.ThresholdHeartRateRideId));
        Assert.Equal((HeartRateNotes.MaxMeasured, HeartRateNotes.ThresholdMeasured),
            (ride.HeartRateMaxNote, ride.HeartRateThresholdNote));
        // Both numbers moved, so both say so: two notifications for one ride.
        var list = await TestApi.WaitForNotificationAsync(member.Client, NotificationTypes.HeartRateMeasured);
        var measured = list.Notifications.Where(n => n.Type == NotificationTypes.HeartRateMeasured).ToArray();
        Assert.Equal(2, measured.Length);
        Assert.Equal(
            ["Maximum 200 bpm", "Threshold 188 bpm"],
            measured.Select(n => n.Subject).Order().ToArray());
    }

    [Fact]
    public async Task HeartRateDetection_ShouldSuggestBoth_WhenBothNumbersWereTyped()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        (await SetAsync(member.Client, "threshold", 165)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, PeakOverBase);

        var suggestions = await SuggestionsAsync(member.Client);
        Assert.Equal(200, suggestions.Single(s => s.Kind == HeartRateKinds.Max).Bpm);
        Assert.Equal(171, suggestions.Single(s => s.Kind == HeartRateKinds.Threshold).Bpm);
        Assert.Equal((HeartRateNotes.MaxSuggested, HeartRateNotes.ThresholdSuggested),
            (ride.HeartRateMaxNote, ride.HeartRateThresholdNote));
        var profile = await ProfileAsync(member.Client);
        Assert.Equal((185, HeartRateSources.Manual), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Equal((165, HeartRateSources.Manual), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
    }

    [Fact]
    public async Task HeartRateDetection_ShouldMeasureTheThreshold_WhenTheMaxWasOnlySuggested()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, PeakOverBase);

        // The maximum stayed where the rider put it, so the threshold is below it and is used as it is.
        var profile = await ProfileAsync(member.Client);
        Assert.Equal((185, HeartRateSources.Manual), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Equal((171, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal((HeartRateNotes.MaxSuggested, HeartRateNotes.ThresholdMeasured),
            (ride.HeartRateMaxNote, ride.HeartRateThresholdNote));
        Assert.DoesNotContain(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Threshold);
    }

    [Fact]
    public async Task HeartRateDetection_ShouldNotSetTheThreshold_WhenItIsNotBelowTheNewMax()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // Every second at the same rate: the maximum moves to 200, and the threshold cannot sit at it.
        var ride = await UploadAsync(member.Client, Yesterday, Flat(200));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((200, HeartRateSources.Measured), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.NotEqual(HeartRateSources.Measured, profile.ThresholdHeartRateSource);
        Assert.Equal(HeartRateNotes.MaxMeasured, ride.HeartRateMaxNote);
        Assert.Null(ride.HeartRateThresholdNote);
    }

    [Fact]
    public async Task HeartRateDetection_ShouldKeepTheLegacyNote_WhenBothHappen()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await UploadAsync(member.Client, Yesterday, BothNumbers);

        // The column an app without the threshold's own field reads keeps the maximum's note.
        Assert.Equal(HeartRateNotes.MaxMeasured, ride.HeartRateNote);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var stored = await db.Rides.AsNoTracking().SingleAsync(r => r.Id == ride.Id, Ct);
        Assert.Equal((HeartRateNotes.MaxMeasured, HeartRateNotes.ThresholdMeasured),
            (stored.HeartRateNote, stored.HeartRateThresholdNote));
    }

    [Fact]
    public async Task CoachRide_ShouldNotCarryTheHeartRateNotes_WhenTheCoachViewsTheRide()
    {
        await using var api = await StartAsync();
        var coachEmail = TestApi.NewEmail();
        (await api.RegisterAsync(coachEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(coachEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, coachEmail);
        var athlete = await api.NewMemberAsync("Athlete Luca");
        await TestClubs.JoinAsync(athlete, club);
        (await athlete.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        var ride = await UploadAsync(athlete.Client, Yesterday, BothNumbers);
        Assert.Equal(HeartRateNotes.ThresholdMeasured, ride.HeartRateThresholdNote);

        var shared = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        Assert.Null(shared!.HeartRateNote);
        Assert.Null(shared.HeartRateMaxNote);
        Assert.Null(shared.HeartRateThresholdNote);
        Assert.Null(shared.FtpSuggestionId);

        // Without the analytics grant the ride answers through WithoutTrainingLoad: the notes are gone there too.
        (await athlete.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "none", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        var withoutAnalytics = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        Assert.Null(withoutAnalytics!.HeartRateNote);
        Assert.Null(withoutAnalytics.HeartRateMaxNote);
        Assert.Null(withoutAnalytics.HeartRateThresholdNote);
        Assert.Null(withoutAnalytics.FtpSuggestionId);
    }

    [Fact]
    public async Task Ride_ShouldNotCarryTheHeartRateNotes_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var owner = await api.NewMemberAsync("Ada");
        var ride = await UploadAsync(owner.Client, Yesterday, BothNumbers);
        var other = await api.NewMemberAsync("Grace");

        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task ThresholdHeartRate_ShouldSkipTheWindow_WhenItHasAPause()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // The half hour at 170 holds the best mean, but a minute of pause sits inside it. The next best window starts
        // when the pause ends and runs into the 150 after the effort: its last 20 minutes average 159 bpm.
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(
            Yesterday.UtcDateTime, 3600, SubSport: SubSport.Road, Pauses: [(1200, 1260)],
            HeartRate: s => (short)(s < 600 || s >= 2400 ? 150 : 170))));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((159, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal(HeartRateNotes.ThresholdMeasured, ride.HeartRateNote);
    }

    [Fact]
    public async Task ThresholdHeartRate_ShouldCountTheEffort_WhenTheStoredMovingTimeIsShorterThanTheSeries()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // The timer ran for 1,700 s over 1,800 s of records with no pause: the window is wall-clock, not moving time.
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(
            Yesterday.UtcDateTime, 1800, SubSport: SubSport.Road, TimerSeconds: 1700,
            HeartRate: s => (short)(s < 600 ? 150 : 165))));

        var profile = await ProfileAsync(member.Client);
        Assert.Equal((165, HeartRateSources.Measured), (profile.ThresholdHeartRate, profile.ThresholdHeartRateSource));
        Assert.Equal(HeartRateNotes.ThresholdMeasured, ride.HeartRateNote);
    }

    [Fact]
    public void ThresholdHeartRate_ShouldSkipTheWindow_WhenTheHeartRateCoversLessThan90Percent()
    {
        // 1,619 seconds of heart rate in the 30-minute window: under the 1,620 the rule asks for.
        var series = new HeartRateSeries(
            [.. Enumerable.Range(0, 1800).Select(s => s < 1619 ? (double?)160 : null)], new bool[1800]);

        Assert.Null(HeartRateDetection.ThresholdCandidate(series));
    }

    [Fact]
    public void ThresholdHeartRate_ShouldUseTheWindow_WhenTheHeartRateCoversExactly90Percent()
    {
        var series = new HeartRateSeries(
            [.. Enumerable.Range(0, 1800).Select(s => s < 1620 ? (double?)160 : null)], new bool[1800]);

        Assert.Equal(160, HeartRateDetection.ThresholdCandidate(series));
    }

    [Theory]
    [InlineData(1741, null)]
    [InlineData(1799, null)]
    [InlineData(1800, 160)]
    public void ThresholdHeartRate_ShouldNeedTheWindow_WhenTheSeriesIsShorter(int seconds, int? expected)
    {
        var series = new HeartRateSeries([.. Enumerable.Repeat<double?>(160, seconds)], new bool[seconds]);

        Assert.Equal(expected, HeartRateDetection.ThresholdCandidate(series));
    }

    [Fact]
    public void ThresholdHeartRate_ShouldBeThirtyRealMinutes_WhenTheRideIsSampledFasterThanOnceASecond()
    {
        // Two samples a second for an hour: one value per second means the 30-minute window is real minutes, and its
        // last 20 minutes are 300 s at 150 and 900 s at 170.
        var samples = Enumerable.Range(0, 3600)
            .Select(i => new Sample(i * 0.5, HeartRate: (short)(i * 0.5 < 900 ? 150 : 170))).ToList();

        var series = HeartRateDetection.Smoothed(samples, []);

        Assert.NotNull(series);
        Assert.Equal(1800, series!.Values.Length);
        Assert.Equal(165, HeartRateDetection.ThresholdCandidate(series));
    }

    [Fact]
    public void MaxHeartRate_ShouldNotChange_WhenTheRideIsSampledAt2Hz()
    {
        // The same effort at one and at two samples a second: one value per wall-clock second, so the peak is the same.
        static short Ramp(double second) => (short)(second < 300 ? 150 : 150 + Math.Min(42, (second - 300) / 2));
        var once = Enumerable.Range(0, 600).Select(s => new Sample(s, HeartRate: Ramp(s))).ToList();
        var twice = Enumerable.Range(0, 1200).Select(i => new Sample(i * 0.5, HeartRate: Ramp(i * 0.5))).ToList();

        var at1Hz = HeartRateDetection.Smoothed(once, []);
        var at2Hz = HeartRateDetection.Smoothed(twice, []);

        Assert.NotNull(at1Hz);
        Assert.NotNull(at2Hz);
        Assert.Equal(600, at2Hz!.Values.Length);
        Assert.Equal(HeartRateDetection.MaxCandidate(at1Hz!), HeartRateDetection.MaxCandidate(at2Hz));
        Assert.Equal(192, HeartRateDetection.MaxCandidate(at2Hz));
    }

    [Fact]
    public void HeartRateDetection_ShouldDropDuplicateAndOutOfOrderSamples_WhenTheSeriesIsBuilt()
    {
        var samples = new List<Sample>
        {
            new(0, HeartRate: 140),
            new(10, HeartRate: 150),
            new(10, HeartRate: 200), // the same instant again says nothing about the next second
            new(5, HeartRate: 210),  // and neither does a sample older than the one before it
            new(20, HeartRate: 160),
        };

        var series = HeartRateDetection.Smoothed(samples, []);

        Assert.NotNull(series);
        Assert.Equal(21, series!.Values.Length);
        Assert.Equal(140, series.Values[0]);
        Assert.Equal(150, series.Values[10]);
        // The two samples the order rule dropped never reach the series.
        Assert.DoesNotContain(series.Values, v => v >= 200);
    }

    [Fact]
    public void ThresholdHeartRate_ShouldStillCount_WhenSecondsHaveNoSignalButNoPause()
    {
        // Ten seconds without a value: under the 10 % the window may miss, and no second is paused.
        var series = new HeartRateSeries(
            [.. Enumerable.Range(0, 1800).Select(s => s is >= 600 and < 610 ? (double?)null : 165)], new bool[1800]);

        Assert.Equal(165, HeartRateDetection.ThresholdCandidate(series));
    }

    [Fact]
    public async Task HeartRateDetection_ShouldNotRun_WhenTheRideIsReadAgain()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        Assert.Equal(MaxCandidate, (await ProfileAsync(member.Client)).MaxHeartRate);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.UserId == member.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ParserVersion, 0), Ct);
        }

        // The rider goes back to the estimate, then the ride is read again: it says nothing a second time.
        (await member.Client.DeleteAsync("/api/v1/accounts/me/heart-rate/max", Ct)).EnsureSuccessStatusCode();
        await api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct);

        var profile = await ProfileAsync(member.Client);
        Assert.NotEqual((MaxCandidate, HeartRateSources.Measured), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            Assert.Equal(RideParserVersion.Current,
                await db.Rides.Where(r => r.UserId == member.Id).Select(r => r.ParserVersion).FirstAsync(Ct));
            // The first read's measured row stays in the history; the re-read wrote no second one.
            Assert.Equal(1, await db.HeartRateHistory.CountAsync(
                h => h.UserId == member.Id && h.Source == HeartRateSources.Measured, Ct));
        }
    }

    [Fact]
    public async Task HeartRateDetection_ShouldNotNotify_WhenTheRideIsQuiet()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var form = new MultipartFormDataContent
        {
            { new ByteArrayContent(Fit(Ride(Yesterday, Flat(MaxCandidate), 1800))), "file", "quiet.fit" },
        };
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads") { Content = form };
        request.Headers.Add("Bulk-Import", "true");
        var accepted = await member.Client.SendAsync(request, Ct);
        accepted.EnsureSuccessStatusCode();
        await TestApi.WaitForReadAsync(member.Client, (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId);

        // The number was still learned; only the notification waits for a ride the member uploaded by hand.
        Assert.Equal(MaxCandidate, (await ProfileAsync(member.Client)).MaxHeartRate);
        var notifications = await member.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct);
        Assert.DoesNotContain(notifications!.Notifications, n => n.Type == NotificationTypes.HeartRateMeasured);
    }

    [Fact]
    public async Task HeartRateDetection_ShouldNotify_WhenTheNumberIsMeasured()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));

        var list = await TestApi.WaitForNotificationAsync(member.Client, NotificationTypes.HeartRateMeasured);
        var notification = Assert.Single(list.Notifications, n => n.Type == NotificationTypes.HeartRateMeasured);
        Assert.Equal((ride.Id, $"Maximum {MaxCandidate} bpm"), (notification.RideId, notification.Subject));
        Assert.Equal(NotificationKinds.Training, NotificationKinds.Of(notification.Type));
    }

    [Fact]
    public async Task HeartRateDetection_ShouldSuggest_WhenTheRiderTypedAThreshold()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "threshold", 150)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 150 : 165));

        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Threshold);
        Assert.Equal((165, ride.Id), (suggestion.Bpm, suggestion.RideId));
        Assert.Equal(HeartRateNotes.ThresholdSuggested, ride.HeartRateNote);
        Assert.Equal(150, (await ProfileAsync(member.Client)).ThresholdHeartRate);
    }

    [Fact]
    public async Task AcceptHeartRateSuggestion_ShouldSetTheValueAsMeasured_WhenOpen()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Max);

        var accepted = await member.Client.PostAsync(
            $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/accept", null, Ct);

        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);
        var profile = (await accepted.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((MaxCandidate, HeartRateSources.Measured), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Empty(await SuggestionsAsync(member.Client));
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var row = await db.HeartRateHistory.AsNoTracking()
            .SingleAsync(h => h.UserId == member.Id && h.Kind == HeartRateKinds.Max && h.Source == HeartRateSources.Measured, Ct);
        Assert.Equal((MaxCandidate, ride.Id), (row.Bpm, row.RideId!.Value));
        Assert.Equal(HeartRateSuggestionStatuses.Accepted,
            (await db.HeartRateSuggestions.AsNoTracking().SingleAsync(s => s.Id == suggestion.Id, Ct)).Status);
    }

    [Fact]
    public async Task AcceptHeartRateSuggestion_ShouldAnswer400_WhenTheThresholdIsNotBelowTheMax()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        (await SetAsync(member.Client, "threshold", 150)).EnsureSuccessStatusCode();
        // The last twenty minutes at 170 suggest a threshold; the ride never beats the maximum of 185.
        await UploadAsync(member.Client, Yesterday, s => (short)(s < 600 ? 150 : 170));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Threshold);
        Assert.Equal(170, suggestion.Bpm);

        // Typing a maximum below the suggestion is the rider's own business; accepting it then is not.
        (await SetAsync(member.Client, "max", 165)).EnsureSuccessStatusCode();
        var accepted = await member.Client.PostAsync(
            $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/accept", null, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, accepted.StatusCode);
        var profile = await ProfileAsync(member.Client);
        Assert.Equal((165, (int?)150), (profile.MaxHeartRate, profile.ThresholdHeartRate));
        Assert.Single(await SuggestionsAsync(member.Client), s => s.Id == suggestion.Id);
    }

    [Fact]
    public async Task HeartRateHistory_ShouldAgreeWithTheColumns_WhenTheSuggestionIsAccepted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Max);

        var accepted = await member.Client.PostAsync(
            $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/accept", null, Ct);
        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Id == member.Id, Ct);
        Assert.Equal((MaxCandidate, HeartRateSources.Measured, (Guid?)ride.Id),
            (user.MaxHeartRateBpm, user.MaxHeartRateSource, user.MaxHeartRateRideId));
        var row = await db.HeartRateHistory.AsNoTracking()
            .Where(h => h.UserId == member.Id && h.Kind == HeartRateKinds.Max)
            .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Sequence)
            .FirstAsync(Ct);
        Assert.Equal((MaxCandidate, HeartRateSources.Measured, (Guid?)ride.Id),
            (row.Bpm, row.Source, row.RideId));
    }

    [Fact]
    public async Task HeartRateSuggestion_ShouldClose_WhenTheRiderTypesTheNumber()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 180)).EnsureSuccessStatusCode();
        await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Max);

        // The rider answers the question themselves, with a number above the one the ride saw.
        (await SetAsync(member.Client, "max", 195)).EnsureSuccessStatusCode();

        Assert.Empty(await SuggestionsAsync(member.Client));
        var accepted = await member.Client.PostAsync(
            $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/accept", null, Ct);
        Assert.Equal(HttpStatusCode.NotFound, accepted.StatusCode);
        Assert.Equal(195, (await ProfileAsync(member.Client)).MaxHeartRate);
    }

    [Fact]
    public async Task HeartRateSuggestion_ShouldStayOpen_WhenTheRiderTypesTheOtherNumber()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client), s => s.Kind == HeartRateKinds.Max);

        (await SetAsync(member.Client, "threshold", 150)).EnsureSuccessStatusCode();

        // Typing the threshold says nothing about the question the ride asked about the maximum.
        Assert.Single(await SuggestionsAsync(member.Client), s => s.Id == suggestion.Id);
    }

    [Fact]
    public async Task DismissHeartRateSuggestion_ShouldHideIt_WhenOpen()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(member.Client));

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.PostAsync(
                $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/dismiss", null, Ct)).StatusCode);

        Assert.Empty(await SuggestionsAsync(member.Client));
        Assert.Equal(185, (await ProfileAsync(member.Client)).MaxHeartRate);
    }

    [Fact]
    public async Task AcceptHeartRateSuggestion_ShouldReturn404_WhenItBelongsToAnotherRider()
    {
        await using var api = await StartAsync();
        var owner = await api.NewMemberAsync("Ada");
        (await SetAsync(owner.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(owner.Client, Yesterday, Flat(MaxCandidate));
        var suggestion = Assert.Single(await SuggestionsAsync(owner.Client));
        var other = await api.NewMemberAsync("Grace");

        Assert.Empty(await SuggestionsAsync(other.Client));
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.PostAsync(
                $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/accept", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.PostAsync(
                $"/api/v1/analytics/heart-rate-suggestions/{suggestion.Id}/dismiss", null, Ct)).StatusCode);
        // Nothing moved for the owner either.
        Assert.Equal(185, (await ProfileAsync(owner.Client)).MaxHeartRate);
        Assert.Single(await SuggestionsAsync(owner.Client));
    }

    [Fact]
    public async Task AccountExport_ShouldContainHeartRateSuggestions_WhenTheMemberHasThem()
    {
        await using var api = await StartAsync(new OffsetTime(DateTimeOffset.UtcNow));
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        (await SetAsync(me.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(me.Client, Yesterday, Flat(MaxCandidate));
        (await SetAsync(other.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(other.Client, Yesterday, Flat(MaxCandidate + 4));

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entry = zip.GetEntry("heart-rate-suggestions.json");
        Assert.NotNull(entry);
        using var stream = entry.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var row = Assert.Single(document.RootElement.EnumerateArray());
        Assert.Equal(MaxCandidate, row.GetProperty("bpm").GetInt32());
        Assert.Equal(HeartRateKinds.Max, row.GetProperty("kind").GetString());
        Assert.Equal(HeartRateSuggestionStatuses.Open, row.GetProperty("status").GetString());
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveHeartRateSuggestions_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync();
        (await SetAsync(me.Client, "max", 185)).EnsureSuccessStatusCode();
        await UploadAsync(me.Client, Yesterday, Flat(MaxCandidate));

        var deleted = await me.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.HeartRateSuggestions.AnyAsync(s => s.UserId == me.Id, Ct));
    }

    [Fact]
    public async Task HeartRateSuggestions_ShouldGoWithTheRide_WhenTheRideIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        (await SetAsync(member.Client, "max", 185)).EnsureSuccessStatusCode();
        var ride = await UploadAsync(member.Client, Yesterday, Flat(MaxCandidate));

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.HeartRateSuggestions.AnyAsync(s => s.RideId == ride.Id, Ct));
    }
}
