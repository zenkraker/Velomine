using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Dynastream.Fit;
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

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// A ride that shows a higher FTP is noticed once, when it is first read: from its best 20, 30 or 60 minutes, for
/// one member's one open suggestion, which they accept in one tap. A coach never sees it.
/// </summary>
public sealed class FtpSuggestionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>A fixed clock, so "42 days ago" is a day and not two. The export link's own expiry follows the
    /// system clock, so the fixed instant stays close to today.</summary>
    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task<HttpResponseMessage> SetFtpAsync(HttpClient client, int watts) =>
        client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(watts), Ct);

    /// <summary>The open suggestion, or null when the server answers 204.</summary>
    private static async Task<FtpSuggestionResponse?> SuggestionAsync(HttpClient client)
    {
        var response = await client.GetAsync("/api/v1/analytics/ftp-suggestion", Ct);
        if (response.StatusCode == HttpStatusCode.NoContent) return null;
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<FtpSuggestionResponse>(Ct);
    }

    /// <summary>A ride of <paramref name="best"/> watts for each given duration, started that many hours before now.</summary>
    private static Task<RideResponse> UploadAsync(
        HttpClient client, double hoursAgo, params (int Seconds, int Watts)[] efforts) =>
        TestApi.UploadAndWaitAsync(client, ClimbingFit(Now.AddHours(-hoursAgo), efforts));

    /// <summary>
    /// A FIT file that holds the given best efforts, each followed by four minutes of pedalling easy, so a window
    /// never spans two efforts (the 1 Hz records alone cannot make a four-minute gap a pause). The ride climbs: each
    /// effort is at least as hard as the one before it.
    /// </summary>
    private static byte[] ClimbingFit(DateTimeOffset start, (int Seconds, int Watts)[] efforts)
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

        var timerStart = new EventMesg();
        timerStart.SetTimestamp(new Dynastream.Fit.DateTime(start.UtcDateTime));
        timerStart.SetEvent(Dynastream.Fit.Event.Timer);
        timerStart.SetEventType(EventType.Start);
        timerStart.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(timerStart);

        var s = 0;
        void Write(int seconds, int watts, bool heartRate)
        {
            for (var i = 0; i < seconds; i++, s++)
            {
                var record = new RecordMesg();
                record.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(s).UtcDateTime));
                record.SetPositionLat((int)(46.0 * (2147483648.0 / 180.0)));
                record.SetPositionLong((int)(11.0 * (2147483648.0 / 180.0)));
                record.SetAltitude(300f);
                record.SetSpeed(8);
                record.SetDistance(s * 8f);
                if (heartRate) record.SetHeartRate(150);
                record.SetPower((ushort)watts);
                record.SetCadence(90);
                encode.Write(record);
            }
        }

        foreach (var (seconds, watts) in efforts)
        {
            Write(seconds, watts, heartRate: true);
            Write(240, 100, heartRate: false);
        }

        var end = start.AddSeconds(s).UtcDateTime;
        var stop = new EventMesg();
        stop.SetTimestamp(new Dynastream.Fit.DateTime(end));
        stop.SetEvent(Dynastream.Fit.Event.Timer);
        stop.SetEventType(EventType.StopAll);
        stop.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(stop);

        var summary = new SessionMesg();
        summary.SetTimestamp(new Dynastream.Fit.DateTime(end));
        summary.SetStartTime(new Dynastream.Fit.DateTime(start.UtcDateTime));
        summary.SetTotalElapsedTime(s);
        summary.SetTotalTimerTime(s);
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

    [Fact]
    public async Task FtpSuggestion_ShouldBeCreated_WhenTwentyMinutesAt280WAndFtpIs250()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        // 25 minutes at 280 W: no 30- or 60-minute best, so the candidate is 95 % of 280 W.
        var ride = await UploadAsync(member.Client, 24, (1500, 280));

        var suggestion = await SuggestionAsync(member.Client);
        Assert.NotNull(suggestion);
        Assert.Equal(266, suggestion.Watts);
        Assert.Equal(FtpSuggestionMethods.TwentyMinutes, suggestion.Method);
        Assert.Equal(280, suggestion.EffortWatts);
        Assert.Equal(ride.Id, suggestion.RideId);
        // The owner's own ride page says the same thing, and can answer it from there.
        Assert.Equal(266, ride.FtpSuggestionW);
        Assert.Equal(FtpSuggestionMethods.TwentyMinutes, ride.FtpSuggestionMethod);
        Assert.Equal(suggestion.Id, ride.FtpSuggestionId);
    }

    [Fact]
    public async Task GetRide_ShouldNameTheSuggestionsEffort_WhenTheRideSuggestsAnFtp()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        await UploadAsync(member.Client, 24, (1500, 280));

        var suggestion = await SuggestionAsync(member.Client);
        var ride = await member.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/rides/{suggestion!.RideId}", Ct);

        // The card says "95 % of your best 20 minutes (280 W)", so the ride carries the effort itself.
        Assert.Equal(suggestion.EffortWatts, ride!.FtpSuggestionEffortW);
        Assert.Equal(280, ride.FtpSuggestionEffortW);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldNotBeCreated_WhenTheCandidateIsLessThanThreePercentAbove()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 260);

        // 266 W is below 260 × 1.03 = 267.8 W: too small a gain to suggest.
        var ride = await UploadAsync(member.Client, 24, (1500, 280));

        Assert.Null(await SuggestionAsync(member.Client));
        Assert.Null(ride.FtpSuggestionW);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldUseTheHour_WhenSixtyMinutesIsHigher()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        // 266 W from the 20 minutes, 268 W from the 30, 270 W from the hour: the hour wins.
        var ride = await UploadAsync(member.Client, 24, (1200, 280), (1800, 276), (3600, 270));

        var suggestion = await SuggestionAsync(member.Client);
        Assert.NotNull(suggestion);
        Assert.Equal(270, suggestion.Watts);
        Assert.Equal(FtpSuggestionMethods.SixtyMinutes, suggestion.Method);
        Assert.Equal(270, suggestion.EffortWatts);
        Assert.Equal(270, ride.FtpSuggestionW);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldUseHalfAnHour_WhenThirtyMinutesIsHighest()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        // 30 minutes at 280 W: one effort, so the 20-minute best is the same 280 W (266 W) and the 30-minute best
        // is 272 W. No 60-minute best exists.
        var ride = await UploadAsync(member.Client, 24, (1800, 280));
        var suggestion = await SuggestionAsync(member.Client);
        Assert.NotNull(suggestion);
        Assert.Equal(272, suggestion.Watts);
        Assert.Equal(FtpSuggestionMethods.ThirtyMinutes, suggestion.Method);
        Assert.Equal(272, ride.FtpSuggestionW);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldBeCreated_WhenTheRiderHasNoFtp()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await UploadAsync(member.Client, 24, (1500, 280));

        var suggestion = await SuggestionAsync(member.Client);
        Assert.NotNull(suggestion);
        Assert.Equal(266, suggestion.Watts);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldReplaceTheOpenOne_WhenAHigherRideArrives()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        await UploadAsync(member.Client, 48, (1500, 280));
        var lower = await SuggestionAsync(member.Client);

        // An hour at 290 W: 290 W is higher than the open 266 W.
        var ride = await UploadAsync(member.Client, 24, (3600, 290));

        var replaced = await SuggestionAsync(member.Client);
        Assert.NotNull(replaced);
        Assert.Equal(290, replaced.Watts);
        Assert.Equal(ride.Id, replaced.RideId);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var old = await db.FtpSuggestions.AsNoTracking().FirstAsync(s => s.Id == lower!.Id, Ct);
        Assert.Equal(FtpSuggestionStatuses.Replaced, old.Status);
        Assert.Single(await db.FtpSuggestions.Where(s => s.UserId == member.Id && s.Status == "open").ToListAsync(Ct));
    }

    [Fact]
    public async Task FtpSuggestion_ShouldKeepIt_WhenALowerRideArrives()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        var strong = await UploadAsync(member.Client, 48, (3600, 290));

        // 95 % of 280 W is 266 W: above the FTP but below the open suggestion.
        var lower = await UploadAsync(member.Client, 24, (1500, 280));

        var kept = await SuggestionAsync(member.Client);
        Assert.NotNull(kept);
        Assert.Equal(290, kept.Watts);
        Assert.Equal(strong.Id, kept.RideId);
        Assert.Null(lower.FtpSuggestionW); // the suggestion stays on the ride that made it
    }

    [Fact]
    public async Task FtpSuggestion_ShouldBeSkipped_WhenTheRideIsAnEbike()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        await UploadAsync(member.Client, 24, (1500, 280));
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.FtpSuggestions.Where(s => s.UserId == member.Id).ExecuteDeleteAsync(Ct);
            await db.Rides.Where(r => r.UserId == member.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.Assist, "ebike"), Ct);
        }

        // The suggestion is worked out from the ride's own flags, so a ride that says it was assisted gets none.
        Ride? found = null;
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            found = await db.Rides.Include(r => r.PowerBests).FirstAsync(r => r.UserId == member.Id, Ct);
        }

        Assert.Equal("ebike", found!.Assist);
        Assert.NotEmpty(found.PowerBests);
        var clock = MemberClock.For(null, System.DayOfWeek.Monday, new FixedTime(Now));
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await FtpSuggestionDetection.AddAsync(db, new FixedTime(Now), clock, found, 250, Ct);
            await db.SaveChangesAsync(Ct);
        }

        Assert.Null(await SuggestionAsync(member.Client));
    }

    [Fact]
    public async Task FtpSuggestion_ShouldBeSkipped_WhenTheRideIsOlderThan42Days()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        // Midday UTC, 43 days ago: the fixture's fixed UTC+2 offset then cannot move the ride to another local date,
        // whatever hour of the day the suite runs at.
        var start = Now.UtcDateTime.Date.AddDays(-43).AddHours(12);
        await UploadAsync(member.Client, (Now.UtcDateTime - start).TotalHours, (1500, 280));

        Assert.Null(await SuggestionAsync(member.Client));
    }

    [Fact]
    public async Task FtpSuggestion_ShouldBeSkipped_WhenTheRideIsReadAgain()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        await UploadAsync(member.Client, 24, (1500, 280));
        var first = await SuggestionAsync(member.Client);
        Assert.NotNull(first);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.FtpSuggestions.Where(s => s.UserId == member.Id).ExecuteDeleteAsync(Ct);
            await db.Rides.Where(r => r.UserId == member.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(r => r.ParserVersion, 0), Ct);
        }

        await ReadAgainAsync(api);

        // The re-read refilled the bests, but a stored ride read again never suggests an FTP.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var rideId = await db.Rides.Where(r => r.UserId == member.Id).Select(r => r.Id).FirstAsync(Ct);
            Assert.Equal(RideParserVersion.Current,
                await db.Rides.Where(r => r.Id == rideId).Select(r => r.ParserVersion).FirstAsync(Ct));
            Assert.True(await db.RidePowerBests.AnyAsync(b => b.RideId == rideId, Ct));
            Assert.False(await db.FtpSuggestions.AnyAsync(s => s.UserId == member.Id, Ct));
        }
    }

    [Fact]
    public async Task FtpSuggestion_ShouldNotNotify_WhenTheRideIsQuiet()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        var form = new MultipartFormDataContent
        {
            { new ByteArrayContent(ClimbingFit(Now.AddHours(-24), [(1500, 280)])), "file", "quiet.fit" },
        };
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads") { Content = form };
        request.Headers.Add("Bulk-Import", "true");
        var accepted = await member.Client.SendAsync(request, Ct);
        accepted.EnsureSuccessStatusCode();
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        await TestApi.WaitForReadAsync(member.Client, id);

        Assert.NotNull(await SuggestionAsync(member.Client));
        var notifications = await member.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct);
        Assert.DoesNotContain(notifications!.Notifications, n => n.Type == NotificationTypes.FtpSuggested);
    }

    [Fact]
    public async Task FtpSuggestion_ShouldNotify_WhenTheRideIsRead()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);

        var ride = await UploadAsync(member.Client, 24, (1500, 280));

        var list = await TestApi.WaitForNotificationAsync(member.Client, NotificationTypes.FtpSuggested);
        var notification = Assert.Single(list.Notifications, n => n.Type == NotificationTypes.FtpSuggested);
        Assert.Equal(ride.Id, notification.RideId);
        Assert.Equal("266 W", notification.Subject);
        Assert.Equal(NotificationKinds.Training, NotificationKinds.Of(notification.Type));
    }

    [Fact]
    public async Task Profile_ShouldSayMeasured_WhenTheFtpSuggestionIsAccepted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 150);
        // Half an hour of 200 W at 150 bpm: a 190 W FTP suggestion, and the ride measures the maximum.
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(
            new FitSession(Now.AddHours(-24).UtcDateTime, 1800)));
        var suggestion = await SuggestionAsync(member.Client);

        var accepted = await member.Client.PostAsync(
            $"/api/v1/analytics/ftp-suggestion/{suggestion!.Id}/accept", null, Ct);

        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);
        // The ride also measured a heart rate: answering the FTP question carries it, with the ride it came from.
        var profile = (await accepted.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((190, 150, HeartRateSources.Measured, (Guid?)ride.Id),
            (profile.FtpW, profile.MaxHeartRate, profile.MaxHeartRateSource, profile.MaxHeartRateRideId));
    }

    [Fact]
    public async Task AcceptFtpSuggestion_ShouldSetFtpAndWriteATestHistoryRow_WhenOpen()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        var ride = await UploadAsync(member.Client, 24, (1500, 280));
        var suggestion = await SuggestionAsync(member.Client);
        var accepted = await member.Client.PostAsync($"/api/v1/analytics/ftp-suggestion/{suggestion!.Id}/accept", null, Ct);

        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);
        var profile = await accepted.Content.ReadFromJsonAsync<ProfileResponse>(Ct);
        Assert.Equal(266, profile!.FtpW);
        var history = await member.Client.GetFromJsonAsync<FtpHistoryResponse>("/api/v1/accounts/me/ftp-history", Ct);
        // A clock that does not tick dates both rows alike, so the row this test made is picked by its source.
        var entry = history!.Entries.Single(e => e.Source == FtpSources.Test);
        Assert.Equal(266, entry.Watts);
        Assert.Equal(ride.Id, entry.RideId);
        Assert.Null(await SuggestionAsync(member.Client));
        var whole = await member.Client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct);
        Assert.Null(whole!.FtpSuggestionW);
    }

    [Fact]
    public async Task DismissFtpSuggestion_ShouldHideIt_WhenOpen()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        await UploadAsync(member.Client, 24, (1500, 280));
        var suggestion = await SuggestionAsync(member.Client);

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.PostAsync($"/api/v1/analytics/ftp-suggestion/{suggestion!.Id}/dismiss", null, Ct)).StatusCode);

        Assert.Null(await SuggestionAsync(member.Client));
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(FtpSuggestionStatuses.Dismissed,
            (await db.FtpSuggestions.AsNoTracking().FirstAsync(s => s.Id == suggestion.Id, Ct)).Status);
    }

    [Fact]
    public async Task AcceptFtpSuggestion_ShouldReturn404_WhenItBelongsToAnotherRider()
    {
        await using var api = await StartAsync();
        var owner = await api.NewMemberAsync("Ada");
        await SetFtpAsync(owner.Client, 250);
        await UploadAsync(owner.Client, 24, (1500, 280));
        var suggestion = await SuggestionAsync(owner.Client);
        var other = await api.NewMemberAsync("Grace");

        Assert.Null(await SuggestionAsync(other.Client));
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.PostAsync($"/api/v1/analytics/ftp-suggestion/{suggestion!.Id}/accept", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.PostAsync($"/api/v1/analytics/ftp-suggestion/{suggestion.Id}/dismiss", null, Ct)).StatusCode);
        // Nothing moved for the owner either.
        Assert.Equal(250, (await owner.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.FtpW);
        Assert.NotNull(await SuggestionAsync(owner.Client));
    }

    [Fact]
    public void RideResponse_ShouldNotCarryASuggestion_WhenAViewerMaySeeNoAnalytics()
    {
        var response = RideResponse.From(new Ride { Id = Guid.NewGuid(), Status = RideStatus.Ready }) with
        {
            FtpSuggestionW = 266,
            FtpSuggestionEffortW = 280,
            FtpSuggestionMethod = FtpSuggestionMethods.TwentyMinutes,
        };

        Assert.Null(response.WithoutTrainingLoad().FtpSuggestionW);
        Assert.Null(response.WithoutTrainingLoad().FtpSuggestionEffortW);
        Assert.Null(response.WithoutTrainingLoad().FtpSuggestionMethod);
    }

    [Fact]
    public async Task CoachRide_ShouldNotShowTheFtpSuggestion_WhenACoachReadsTheRide()
    {
        await using var api = await StartAsync();
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(ownerEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, ownerEmail);
        var athlete = await api.NewMemberAsync("Athlete Luca");
        await TestClubs.JoinAsync(athlete, club);
        (await athlete.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        await SetFtpAsync(athlete.Client, 250);
        var ride = await UploadAsync(athlete.Client, 24, (1500, 280));

        var shared = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);

        Assert.NotNull(shared);
        Assert.Null(shared.FtpSuggestionW);
        Assert.Null(shared.FtpSuggestionEffortW);
        Assert.Null(shared.FtpSuggestionMethod);
    }

    [Fact]
    public async Task AccountExport_ShouldContainFtpSuggestions_WhenTheMemberHasThem()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetFtpAsync(me.Client, 250);
        await UploadAsync(me.Client, 24, (1500, 280));
        await SetFtpAsync(other.Client, 250);
        await UploadAsync(other.Client, 24, (3600, 300));

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entry = zip.GetEntry("ftp-suggestions.json");
        Assert.NotNull(entry);
        using var stream = entry.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var row = document.RootElement.EnumerateArray()
            .Single(r => r.GetProperty("status").GetString() == "open");
        Assert.Equal(266, row.GetProperty("watts").GetInt32());
        Assert.Equal(FtpSuggestionMethods.TwentyMinutes, row.GetProperty("method").GetString());
        Assert.Equal(FtpSuggestionStatuses.Open, row.GetProperty("status").GetString());
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveFtpSuggestions_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync();
        await SetFtpAsync(me.Client, 250);
        await UploadAsync(me.Client, 24, (1500, 280));

        var deleted = await me.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.FtpSuggestions.AnyAsync(s => s.UserId == me.Id, Ct));
    }

    [Fact]
    public async Task FtpSuggestions_ShouldGoWithTheRide_WhenTheRideIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpAsync(member.Client, 250);
        var ride = await UploadAsync(member.Client, 24, (1500, 280));

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.FtpSuggestions.AnyAsync(s => s.RideId == ride.Id, Ct));
    }

    /// <summary>Reads every stored ride again, as a parser version bump does.</summary>
    private static Task ReadAgainAsync(TestApi api) =>
        api.Services.GetRequiredService<RideReparseService>().RunAsync(Ct);
}
