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
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Analytics;

public sealed class PowerRecordsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
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

    /// <summary>A ride of constant power, started that many hours before <see cref="Now"/>.</summary>
    private static Task<RideResponse> UploadAsync(HttpClient client, int watts, double hoursAgo, int seconds = 3700) =>
        TestApi.UploadAndWaitAsync(client, SteadyFit(Now.AddHours(-hoursAgo), seconds, watts));

    private static Task<RideResponse> GetRideAsync(HttpClient client, Guid id) =>
        client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct)!;

    /// <summary>The ride's records as the member's own ride page shows them.</summary>
    private static async Task<PowerRecord[]> RecordsOfAsync(HttpClient client, Guid id) =>
        (await GetRideAsync(client, id)).PowerRecords!;

    /// <summary>The list the member sees; a quiet or older ride may simply have no such notification.</summary>
    private static async Task<NotificationResponse[]> NotificationsAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!
            .Notifications.Where(n => n.Type == NotificationTypes.PowerRecord).ToArray();

    [Fact]
    public async Task PowerRecords_ShouldMarkAllTime_WhenTheRideBeatsEveryEarlierRide()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 48);
        var stronger = await UploadAsync(client, 260, 24);

        var records = await RecordsOfAsync(client, stronger.Id);

        Assert.Equal(PowerRecords.Durations, records.Select(r => r.DurationS));
        Assert.All(records, r => Assert.Equal(PowerRecords.AllTime, r.Kind));
        Assert.All(records, r => Assert.Equal(260, r.Watts));
    }

    [Fact]
    public async Task PowerRecords_ShouldNotMark_WhenTheRideOnlyEqualsTheBest()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 48);
        // Shorter and an hour apart: a ride of its own, not a duplicate of the first.
        var same = await UploadAsync(client, 200, 47, seconds: 3600);

        Assert.Empty(await RecordsOfAsync(client, same.Id));
    }

    [Fact]
    public async Task PowerRecords_ShouldMarkNinetyDays_WhenOnlyOlderRidesWereBetter()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 300, 24 * 120);
        var recent = await UploadAsync(client, 260, 24);

        var records = await RecordsOfAsync(client, recent.Id);

        Assert.All(records, r => Assert.Equal(PowerRecords.NinetyDays, r.Kind));
        Assert.All(records, r => Assert.Equal(260, r.Watts));
    }

    [Fact]
    public async Task PowerRecords_ShouldIgnoreLaterRides_WhenAskedAboutAnOlderRide()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 72);
        var middle = await UploadAsync(client, 260, 48);
        await UploadAsync(client, 300, 24);

        var records = await RecordsOfAsync(client, middle.Id);

        Assert.All(records, r => Assert.Equal(PowerRecords.AllTime, r.Kind));
        Assert.All(records, r => Assert.Equal(260, r.Watts));
    }

    [Fact]
    public async Task PowerRecords_ShouldBeEmpty_WhenItIsTheFirstPowerRide()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        var first = await UploadAsync(client, 300, 24);
        Assert.Empty(await RecordsOfAsync(client, first.Id));
    }

    [Fact]
    public async Task PowerRecords_ShouldIgnoreOneSecond_WhenItIsTheOnlyRecord()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        // Six seconds long: only the 1 s and 5 s bests exist, and only the 5 s one may be a record.
        await UploadAsync(client, 200, 48, seconds: 6);
        var ride = await UploadAsync(client, 260, 24, seconds: 6);

        Assert.Equal([new PowerRecord(5, 260, PowerRecords.AllTime)], await RecordsOfAsync(client, ride.Id));
    }

    [Fact]
    public async Task PowerRecordNotification_ShouldBeCreated_WhenAnAllTimeRecordIsSet()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 48);

        var stronger = await UploadAsync(client, 260, 24);

        var notification = Assert.Single(await NotificationsAsync(client));
        Assert.Equal(stronger.Id, notification.RideId);
        Assert.Equal("60 min: 260 W", notification.Subject);
    }

    [Fact]
    public async Task PowerRecordNotification_ShouldNotBeCreated_WhenTheRideIsQuiet()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 48);

        var form = new MultipartFormDataContent
        {
            { new ByteArrayContent(SteadyFit(Now.AddHours(-24), 3700, 260)), "file", "quiet.fit" },
        };
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads") { Content = form };
        request.Headers.Add("Bulk-Import", "true");
        var accepted = await client.SendAsync(request, Ct);
        accepted.EnsureSuccessStatusCode();
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        var quiet = await TestApi.WaitForReadAsync(client, id);

        Assert.NotEmpty(await RecordsOfAsync(client, quiet.Id)); // the records are still there when read
        Assert.Empty(await NotificationsAsync(client));
    }

    [Fact]
    public async Task PowerRecordNotification_ShouldNotBeCreated_WhenTheRideIsOlderThan30Days()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await UploadAsync(client, 200, 24 * 40);

        var old = await UploadAsync(client, 260, 24 * 31);

        Assert.NotEmpty(await RecordsOfAsync(client, old.Id)); // it is still a record when read
        Assert.Empty(await NotificationsAsync(client));
    }

    [Fact]
    public async Task CoachRide_ShouldShowPowerRecords_WhenTheRiderSharesRides()
    {
        await using var api = await StartAsync();
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(ownerEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, ownerEmail);
        var (athlete, athleteId) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        (await athlete.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" }, Ct))
            .EnsureSuccessStatusCode();
        await UploadAsync(athlete, 200, 48);
        var record = await UploadAsync(athlete, 260, 24);

        var shared = await coach.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athleteId}/rides/{record.Id}", Ct);

        // The records are a number about the ride, so the rider who shares rides shares them.
        Assert.NotEmpty(shared!.PowerRecords!);
        Assert.NotNull(shared.NormalizedPowerW);
    }

    [Fact]
    public async Task CoachRide_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Club Owner")).EnsureSuccessStatusCode();
        var club = await TestClubs.CreateAsync(api, ownerEmail);
        var (outsider, _) = await NewMemberAsync(api, "Outsider Sam");

        var (athlete, athleteId) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        await UploadAsync(athlete, 200, 48);
        var record = await UploadAsync(athlete, 260, 24);

        var response = await outsider.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athleteId}/rides/{record.Id}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task PowerRecords_ShouldNotBeVisible_WhenTheRideBelongsToAnotherMember()
    {
        await using var api = await StartAsync();
        var (owner, _) = await NewMemberAsync(api);
        await UploadAsync(owner, 200, 48);
        var record = await UploadAsync(owner, 260, 24);
        var (stranger, _) = await NewMemberAsync(api, "Someone Else");

        Assert.Equal(HttpStatusCode.NotFound, (await stranger.GetAsync($"/api/v1/rides/{record.Id}", Ct)).StatusCode);
    }

    [Fact]
    public void PowerRecords_ShouldSkipOneSecond_WhenListingTheDurationsThatCount()
    {
        Assert.Equal([5, 15, 30, 60, 120, 300, 600, 1200, 1800, 3600], PowerRecords.Durations);
        Assert.Equal("5 s", PowerRecords.DurationWord(5));
        Assert.Equal("1 min", PowerRecords.DurationWord(60));
        Assert.Equal("20 min", PowerRecords.DurationWord(1200));
    }

    /// <summary>A FIT file riding at one power every second: the test files' own shape, with the power the test needs.</summary>
    private static byte[] SteadyFit(DateTimeOffset start, int seconds, int watts)
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

        for (var s = 0; s < seconds; s++)
        {
            var record = new RecordMesg();
            record.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(s).UtcDateTime));
            record.SetPositionLat((int)(46.0 * (2147483648.0 / 180.0)));
            record.SetPositionLong((int)(11.0 * (2147483648.0 / 180.0)));
            record.SetAltitude(300f);
            record.SetSpeed(8);
            record.SetDistance(s * 8f);
            record.SetHeartRate(150);
            record.SetPower((ushort)watts);
            record.SetCadence(90);
            encode.Write(record);
        }

        var end = start.AddSeconds(seconds).UtcDateTime;
        var stop = new EventMesg();
        stop.SetTimestamp(new Dynastream.Fit.DateTime(end));
        stop.SetEvent(Dynastream.Fit.Event.Timer);
        stop.SetEventType(EventType.StopAll);
        stop.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(stop);

        var summary = new SessionMesg();
        summary.SetTimestamp(new Dynastream.Fit.DateTime(end));
        summary.SetStartTime(new Dynastream.Fit.DateTime(start.UtcDateTime));
        summary.SetTotalElapsedTime(seconds);
        summary.SetTotalTimerTime(seconds);
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
}
