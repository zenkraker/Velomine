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
using static Velomine.Server.Tests.Rides.TestRideFiles;
using SubSport = Dynastream.Fit.SubSport;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// A ride that shows a higher heart rate teaches Velomine the number, once, when the ride is first read: a number the
/// rider typed is only suggested, a number that was estimated or measured before is used. A lower one never counts.
/// </summary>
public sealed class HeartRateDetectionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow;

    /// <summary>The estimate when no age is known and no maximum is set: 89 % is the threshold, 208 the maximum's own.</summary>
    private const int MaxCandidate = 200;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
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
        await using var api = await StartAsync();
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
