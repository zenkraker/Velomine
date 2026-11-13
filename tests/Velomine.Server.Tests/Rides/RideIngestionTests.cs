using System.Net;
using System.Net.Http.Json;
using Dynastream.Fit;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;
using Microsoft.EntityFrameworkCore;

namespace Velomine.Server.Tests.Rides;

public sealed class RideIngestionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            more?.Invoke(b);
        });

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static Task<HttpResponseMessage> UploadAsync(HttpClient client, byte[] file, string name = "ride.fit", string? key = null, bool bulk = false)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads") { Content = form };
        if (key is not null) request.Headers.Add("Idempotency-Key", key);
        if (bulk) request.Headers.Add("Bulk-Import", "true");
        return client.SendAsync(request, Ct);
    }

    /// <summary>Uploads and waits until the background reader is done with the ride.</summary>
    private static async Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file, string name = "ride.fit", string? key = null)
    {
        var accepted = await UploadAsync(client, file, name, key);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        return await WaitAsync(client, id);
    }

    private static async Task<RideResponse> WaitAsync(HttpClient client, Guid id)
    {
        for (var i = 0; i < 100; i++)
        {
            var ride = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct);
            if (ride!.Status != "processing") return ride;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

    private static int OriginalFileCount(TestApi api) =>
        Directory.GetFiles(api.FilesPath, "*", SearchOption.AllDirectories).Count(f => f.Contains("originals"));

    [Fact]
    public async Task UploadRide_ShouldStoreAReadyRideWithMetrics_WhenGivenAFitFile()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120, NormalizedPower: 215)));

        Assert.Equal("ready", ride.Status);
        Assert.Equal(new DateTimeOffset(Start), ride.StartTime);
        Assert.Equal(120, ride.UtcOffsetMinutes);
        Assert.Equal("Garmin", ride.Device);
        Assert.Equal("ride.fit", ride.FileName);
        Assert.Equal(120, ride.ElapsedS); // the session's elapsed time, one second longer than the last sample's timestamp
        Assert.Equal(119 * 8.0, ride.DistanceM!.Value, 1);
        Assert.Equal("device", ride.SpeedSource);
        Assert.Equal(8, ride.MaxSpeedMs!.Value, 3);
        Assert.Equal(200, ride.AvgPowerW);
        Assert.Equal(215, ride.NormalizedPowerW); // the device's own value is kept
        Assert.Equal(150, ride.AvgHeartRate);
        Assert.Equal(90, ride.AvgCadence);
        Assert.InRange(ride.ElevationGainM!.Value, 10, 13); // 0.1 m per second for ~2 minutes
    }

    [Fact]
    public async Task UploadRide_ShouldUseGpsSpeedAndWorkOutNormalizedPower_WhenGpxHasNoSpeed()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var gpx = Gpx(180, i => $"<gpxpx:PowerExtension><gpxpx:PowerInWatts>{(i % 60 < 30 ? 150 : 250)}</gpxpx:PowerInWatts></gpxpx:PowerExtension>");

        var ride = await UploadAndWaitAsync(member, Bytes(gpx), "morning.gpx");

        Assert.Equal("ready", ride.Status);
        Assert.Equal("gps", ride.SpeedSource);
        Assert.Equal(179 * 8.0, ride.DistanceM!.Value, 0); // within about 10 m
        Assert.Equal(200, ride.AvgPowerW);
        Assert.Equal(250, ride.MaxPowerW);
        Assert.InRange(ride.NormalizedPowerW!.Value, 200, 215);
        Assert.Equal(0, ride.UtcOffsetMinutes); // no member zone: UTC
    }

    [Fact]
    public async Task UploadRide_ShouldStoreTheRidersOffset_WhenTheGpxHasNoOffset()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await SetProfileAsync(member, "Europe/Rome");

        var ride = await UploadAndWaitAsync(member, Bytes(Gpx(60)), "morning.gpx");

        Assert.Equal(120, ride.UtcOffsetMinutes); // Rome in October is UTC+2
    }

    [Fact]
    public async Task Totals_ShouldNotChange_WhenTheMemberChangesTimeZoneAfterUpload()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await SetProfileAsync(member, "Europe/Rome", "sunday");
        // Saturday 31 October 23:30 UTC is Sunday 1 November in Rome.
        var ride = await UploadAndWaitAsync(member, Bytes(Gpx(60, start: new System.DateTime(2026, 10, 31, 23, 30, 0, DateTimeKind.Utc))), "night.gpx");
        Assert.Equal(60, ride.UtcOffsetMinutes);

        await SetProfileAsync(member, "UTC", "sunday");

        var totals = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=week&count=2", Ct);
        Assert.Equal(new DateOnly(2026, 11, 1), totals!.Totals[0].Start);
        Assert.Equal(1, totals.Totals[0].Rides);
        Assert.Equal(0, totals.Totals[1].Rides);
    }

    private static async Task SetProfileAsync(HttpClient client, string timeZone, string firstDay = "monday") =>
        (await client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new Server.Features.Accounts.UpdateProfileRequest("Test Rider", null, null, null, timeZone, firstDay), Ct))
        .EnsureSuccessStatusCode();

    [Fact]
    public async Task UploadRide_ShouldStoreStreamsAlignedBySample_WhenTheFileIsRead()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var streams = await db.RideStreams.AsNoTracking().SingleAsync(s => s.RideId == ride.Id, Ct);

        Assert.Equal(120, streams.Time.Length);
        Assert.Equal(119, streams.Time[^1]);
        Assert.All(streams.Power!, p => Assert.Equal((short?)200, p));
        Assert.All(streams.HeartRate!, p => Assert.Equal((short?)150, p));
        Assert.All(streams.Temperature!, p => Assert.Equal((short?)18, p));
        Assert.Equal(120, streams.Latitude!.Length);
        Assert.InRange(streams.Latitude[119]!.Value, 46.0085, 46.0087); // 952 m north of 46.0
        Assert.Equal(119 * 8f, streams.Distance![119]);
    }

    [Fact]
    public async Task GetRideStreams_ShouldReturnAlignedArraysAndThinThem_WhenRequested()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));

        var all = await member.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{ride.Id}/streams", Ct);
        Assert.Equal(120, all!.Time.Length);
        Assert.Equal(120, all.Power!.Length);
        Assert.Equal(119, all.Time[^1]);
        Assert.NotNull(all.Speed);

        var thin = await member.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/rides/{ride.Id}/streams?maxPoints=30", Ct);
        Assert.Equal(30, thin!.Time.Length);
        Assert.All(thin.Power!, p => Assert.Equal((short?)200, p));
        Assert.All(thin.HeartRate!, p => Assert.Equal((short?)150, p));

        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync($"/api/v1/rides/{ride.Id}/streams?maxPoints=5", Ct)).StatusCode);
    }

    [Fact]
    public async Task GetRideStreams_ShouldBeHiddenFromNonOwners_WhenTheRideIsNotTheirs()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var ready = await UploadAndWaitAsync(alice, Fit(new FitSession(Start, 90)));
        var failed = await UploadAndWaitAsync(alice, Bytes("not a ride"), "note.txt");

        Assert.Equal(HttpStatusCode.NotFound, (await bob.GetAsync($"/api/v1/rides/{ready.Id}/streams", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await alice.GetAsync($"/api/v1/rides/{Guid.NewGuid()}/streams", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await alice.GetAsync($"/api/v1/rides/{failed.Id}/streams", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync($"/api/v1/rides/{ready.Id}/streams", Ct)).StatusCode);
    }

    [Fact]
    public async Task UploadRide_ShouldReturnTheSameRide_WhenRetriedWithTheSameKey()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 90));

        var first = await (await UploadAsync(member, file, key: "phone-ride-1")).Content.ReadFromJsonAsync<UploadRideResponse>(Ct);
        var retry = await UploadAsync(member, file, key: "phone-ride-1");

        Assert.Equal(HttpStatusCode.Accepted, retry.StatusCode);
        Assert.Equal(first!.RideId, (await retry.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId);
        await WaitAsync(member, first.RideId);
        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        Assert.Single(list!.Rides);
    }

    [Fact]
    public async Task UploadRide_ShouldDeleteTheRejectedFile_WhenTheKeyIsReusedForAnotherFile()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await UploadAndWaitAsync(member, Fit(new FitSession(Start, 90)), key: "k1");

        var other = await UploadAsync(member, Fit(new FitSession(Start.AddDays(1), 90)), key: "k1");

        Assert.Equal(HttpStatusCode.Conflict, other.StatusCode);
        Assert.Equal(1, OriginalFileCount(api));
    }

    [Fact]
    public async Task UploadRide_ShouldReturnAHiddenDuplicate_WhenTheSameFileIsUploadedAgain()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 90));
        var first = await UploadAndWaitAsync(member, file);

        var again = await UploadAndWaitAsync(member, file, key: "other-key");

        Assert.Equal("duplicate", again.Status);
        Assert.Equal(first.Id, again.DuplicateOf);
        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        Assert.Equal(first.Id, Assert.Single(list!.Rides).Id);
    }

    [Fact]
    public async Task UploadRide_ShouldMakeNoNotification_WhenTheFilesCameInABulkDrop()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 90));
        var broken = Bytes("not a ride");

        async Task<RideResponse> BulkAsync(byte[] bytes, string key)
        {
            var accepted = await UploadAsync(member, bytes, key: key, bulk: true);
            Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
            return await WaitAsync(member, (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId);
        }

        Assert.Equal("ready", (await BulkAsync(file, "a")).Status);
        Assert.Equal("duplicate", (await BulkAsync(file, "b")).Status);
        Assert.Equal("failed", (await BulkAsync(broken, "c")).Status);

        var notifications = await member.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct);
        Assert.Empty(notifications!.Notifications);
    }

    [Fact]
    public async Task UploadRide_ShouldNotifyTheMember_WhenASingleFileIsUploaded()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await UploadAndWaitAsync(member, Fit(new FitSession(Start, 90)));

        var notifications = await member.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct);
        Assert.Single(notifications!.Notifications);
    }

    [Fact]
    public async Task UploadRide_ShouldKeepOneRide_WhenTheSameFileIsUploadedTwiceAtOnce()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 90));

        var firstUpload = UploadAsync(member, file);
        var secondUpload = UploadAsync(member, file);
        var firstId = (await (await firstUpload).Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        var secondId = (await (await secondUpload).Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;

        var first = await WaitAsync(member, firstId);
        var second = await WaitAsync(member, secondId);

        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        var visible = Assert.Single(list!.Rides);
        Assert.Contains(new[] { first, second },
            ride => ride.Status == "duplicate" && ride.DuplicateOf == visible.Id);
    }

    [Fact]
    public async Task UploadRide_ShouldCreateTwoRides_WhenTheFileHasTwoSessions()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var first = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 90), new FitSession(Start.AddHours(3), 60)));

        Assert.Equal("ready", first.Status);
        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        Assert.Equal(2, list!.Rides.Length);
        Assert.All(list.Rides, r => Assert.Equal("ready", r.Status));
        Assert.Equal([Start.AddHours(3), Start], list.Rides.Select(r => r.StartTime!.Value.UtcDateTime).ToArray()); // newest first
    }

    [Theory]
    [InlineData("a note, not a ride", "invalid_file")]
    [InlineData("<recipe/>", "unsupported_format")]
    public async Task UploadRide_ShouldFailWithAReasonAndKeepTheFile_WhenItIsNotARide(string content, string error)
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ride = await UploadAndWaitAsync(member, Bytes(content), "note.txt");

        Assert.Equal("failed", ride.Status);
        Assert.Equal(error, ride.Error);
        Assert.Single(Directory.GetFiles(api.FilesPath, "*", SearchOption.AllDirectories), f => f.Contains("originals"));
    }

    [Fact]
    public async Task UploadRide_ShouldFailAsNotCycling_WhenTheActivityIsARun()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60, Sport.Running)));

        Assert.Equal("failed", ride.Status);
        Assert.Equal("not_cycling", ride.Error);
    }

    [Fact]
    public async Task UploadRide_ShouldAcceptTheRequest_WhenSentAsTheGeneratedDartClientDoes()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        // The generated client adds a plain text field "file" with the value "file" next to the file part.
        var form = new MultipartFormDataContent
        {
            { new StringContent("file"), "file" },
            { new ByteArrayContent(Bytes(Gpx(60))), "file", "morning.gpx" },
        };
        var response = await member.PostAsync("/api/v1/rides/uploads", form, Ct);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var id = (await response.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        Assert.Equal("ready", (await WaitAsync(member, id)).Status);
    }

    [Fact]
    public async Task UploadRide_ShouldRejectTheRequest_WhenTwoFilesAreSent()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var form = new MultipartFormDataContent
        {
            { new ByteArrayContent(Bytes(Gpx(60))), "file", "a.gpx" },
            { new ByteArrayContent(Bytes(Gpx(60))), "file", "b.gpx" },
        };

        Assert.Equal(HttpStatusCode.BadRequest, (await member.PostAsync("/api/v1/rides/uploads", form, Ct)).StatusCode);
    }

    [Fact]
    public async Task UploadRide_ShouldRejectTheRequest_WhenTheFileIsEmpty()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var response = await UploadAsync(member, []);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Rides_ShouldBeInvisibleToOtherMembers_WhenTheyBelongToSomeoneElse()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(alice, Fit(new FitSession(Start, 90)));

        Assert.Equal(HttpStatusCode.NotFound, (await bob.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await bob.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
        Assert.Empty((await bob.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
        Assert.Equal(HttpStatusCode.OK, (await alice.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task ListRides_ShouldPageNewestFirst_WhenThereAreMoreRidesThanTheLimit()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        foreach (var day in new[] { 1, 2, 3 }) await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(day), 60)));

        var page1 = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?limit=2", Ct);
        Assert.Equal([Start.AddDays(3), Start.AddDays(2)], page1!.Rides.Select(r => r.StartTime!.Value.UtcDateTime).ToArray());
        Assert.NotNull(page1.Next);

        var page2 = await member.GetFromJsonAsync<ListRidesResponse>($"/api/v1/rides?limit=2&cursor={Uri.EscapeDataString(page1.Next)}", Ct);
        Assert.Equal([Start.AddDays(1)], page2!.Rides.Select(r => r.StartTime!.Value.UtcDateTime).ToArray());
        Assert.Null(page2.Next);

        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync("/api/v1/rides?cursor=nonsense", Ct)).StatusCode);
    }

    [Fact]
    public async Task DeleteRide_ShouldRemoveTheRideAndItsFile_WhenItIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 90)));

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.NotFound, (await member.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
        Assert.DoesNotContain(Directory.GetFiles(api.FilesPath, "*", SearchOption.AllDirectories), f => f.Contains("originals"));
        await using var scope = api.Services.CreateAsyncScope();
        Assert.False(await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().RideStreams.AnyAsync(s => s.RideId == ride.Id, Ct));
    }

    [Fact]
    public async Task UploadRide_ShouldStoreTheDistance_WhenAnIndoorFileHasAPause()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(
            Start, 60, Pauses: new[] { (10, 20) }, SubSport: SubSport.IndoorCycling, NoPosition: true)));

        Assert.Equal("ready", ride.Status);
        Assert.Equal("indoor", ride.Environment);
        Assert.InRange(ride.DistanceM!.Value, 470, 475);
    }

    [Fact]
    public async Task DeleteRide_ShouldBringBackTheHiddenCopy_WhenTheKeptRideIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var file = Fit(new FitSession(Start, 90));
        var visible = await UploadAndWaitAsync(member, file);
        var duplicate = await UploadAndWaitAsync(member, file, key: "other-key");
        Assert.Equal("duplicate", duplicate.Status);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/rides/{visible.Id}", Ct)).StatusCode);

        Assert.Equal("ready", (await WaitAsync(member, duplicate.Id)).Status);
        Assert.Equal(1, OriginalFileCount(api)); // the copy was read from the same file, which the surviving ride needs
    }

    [Fact]
    public async Task RideIngestionService_ShouldReadLeftoverRides_WhenTheServerStartsAgain()
    {
        await using var first = await StartAsync();
        var member = await NewMemberAsync(first);
        var userId = (await member.GetFromJsonAsync<Server.Features.Accounts.MeResponse>("/api/v1/accounts/me", Ct))!.Id;

        // As if the server stopped after saving the upload but before reading it.
        string sha;
        await using (var scope = first.Services.CreateAsyncScope())
        {
            sha = await scope.ServiceProvider.GetRequiredService<RideFileStore>().SaveAsync(new MemoryStream(Fit(new FitSession(Start, 90))), Ct);
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            db.Rides.Add(new Ride { Id = Guid.CreateVersion7(), UserId = userId, Status = RideStatus.Processing, FileSha256 = sha, FileName = "left.fit", UploadedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync(Ct);
        }

        await using var second = await StartAsync(b =>
        {
            b.UseSetting("ConnectionStrings:Velomine", first.ConnectionString);
            b.UseSetting("Velomine:FilesPath", first.FilesPath);
        });
        var again = await second.SignedInClientAsync(
            (await first.Services.CreateAsyncScope().ServiceProvider.GetRequiredService<VelomineDbContext>().Users.AsNoTracking().SingleAsync(u => u.Id == userId, Ct)).Email!,
            TestApi.MemberPassword);
        var listed = await again.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);

        var ride = await WaitAsync(again, listed!.Rides.Single().Id);
        Assert.Equal("ready", ride.Status);
    }

    [Fact]
    public async Task UploadRide_ShouldStoreTheDimensions_WhenTheFitSessionHasASubSport()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60, Sport.EBiking, SubSport: SubSport.EBikeMountain)));

        Assert.Equal("mountain", ride.Discipline);
        Assert.Equal("ebike", ride.Assist);
        Assert.Equal("outdoor", ride.Environment);
        Assert.Null(ride.Commute);
    }

    [Fact]
    public async Task SetRideType_ShouldChangeTheDimensions_WhenTheMemberOwnsTheRide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60)));

        var response = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/type", new
        {
            Discipline = "mountain",
            Assist = "ebike",
            Environment = "indoor",
            Commute = true,
        }, Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var changed = await response.Content.ReadFromJsonAsync<RideResponse>(Ct);
        Assert.Equal("mountain", changed!.Discipline);
        Assert.Equal("ebike", changed.Assist);
        Assert.Equal("indoor", changed.Environment);
        Assert.True(changed.Commute);

        var again = await member.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct);
        Assert.Equal("mountain", again!.Discipline);
        Assert.Equal("ebike", again.Assist);
        Assert.Equal("indoor", again.Environment);
        Assert.True(again.Commute);
    }

    [Fact]
    public async Task SetRideType_ShouldRejectAnUnknownDiscipline_WhenTheBodyHasOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60)));

        var response = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/type", new { Discipline = "rowing" }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SetRideType_ShouldReturnNotFound_WhenTheRideBelongsToSomeoneElse()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(alice, Fit(new FitSession(Start, 60)));

        var response = await bob.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/type", new { Discipline = "gravel" }, Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task SetRideType_ShouldReturnConflict_WhenTheRideChangedOnAnotherDevice()
    {
        var conflict = new ForcedConflict();
        await using var api = await StartAsync(b => b.ConfigureTestServices(s => s.AddSingleton<IInterceptor>(conflict)));
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60)));
        conflict.RideId = ride.Id;

        var response = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/type", new { Discipline = "gravel" }, Ct);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    /// <summary>Makes the ride's update carry an old xmin, as a second device's save would.</summary>
    private sealed class ForcedConflict : SaveChangesInterceptor
    {
        public Guid? RideId { get; set; }

        public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData,
            InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            Conflict(eventData);
            return ValueTask.FromResult(result);
        }

        public override InterceptionResult<int> SavingChanges(DbContextEventData eventData, InterceptionResult<int> result)
        {
            Conflict(eventData);
            return result;
        }

        private void Conflict(DbContextEventData eventData)
        {
            if (eventData.Context is not { } db || RideId is not { } id) return;
            foreach (var entry in db.ChangeTracker.Entries<Ride>()
                         .Where(e => e.State == EntityState.Modified && e.Entity.Id == id))
                entry.Property(r => r.Version).OriginalValue = 0u;
        }
    }

    [Fact]
    public async Task ListRides_ShouldApplyEveryDimensionFilter_WhenSeveralAreGiven()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(1), 60, SubSport: SubSport.Road)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(2), 60, SubSport: SubSport.GravelCycling)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(3), 60, Sport.EBiking, SubSport: SubSport.EBikeMountain)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(4), 60, SubSport: SubSport.IndoorCycling)));

        var gravel = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?discipline=gravel", Ct);
        Assert.Equal("gravel", Assert.Single(gravel!.Rides).Discipline);

        var indoor = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?environment=indoor", Ct);
        Assert.Equal("indoor", Assert.Single(indoor!.Rides).Environment);

        var eMountain = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?discipline=mountain&assist=ebike", Ct);
        Assert.Equal("mountain", Assert.Single(eMountain!.Rides).Discipline);

        var none = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?discipline=road&assist=ebike", Ct);
        Assert.Empty(none!.Rides);

        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync("/api/v1/rides?discipline=rowing", Ct)).StatusCode);
    }

    [Fact]
    public async Task UploadRide_ShouldStoreComputedLaps_WhenTheFileHasThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120, LapSeconds: [60, 60])));

        var laps = await member.GetFromJsonAsync<RideLapsResponse>($"/api/v1/rides/{ride.Id}/laps", Ct);

        Assert.Equal([1, 2], laps!.Laps.Select(l => l.Index).ToArray());
        Assert.Equal(0, laps.Laps[0].StartS);
        Assert.Equal(60, laps.Laps[0].EndS);
        Assert.Equal(60, laps.Laps[1].StartS);
        Assert.Equal(119, laps.Laps[1].EndS);
        Assert.InRange(laps.Laps.Sum(l => l.DistanceM), ride.DistanceM!.Value - 1, ride.DistanceM.Value + 1);
        Assert.InRange(laps.Laps.Sum(l => l.MovingS), ride.MovingS!.Value - 2, ride.MovingS.Value + 2);
    }

    [Fact]
    public async Task GetRideLaps_ShouldReturnNone_WhenTheFileHasNoLaps()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadAndWaitAsync(member, Fit(new FitSession(Start, 60)));

        var laps = await member.GetFromJsonAsync<RideLapsResponse>($"/api/v1/rides/{ride.Id}/laps", Ct);

        Assert.Empty(laps!.Laps);
    }

    [Fact]
    public async Task GetRideLaps_ShouldBeHiddenOrRefused_WhenTheRideIsNotReadyOrNotMine()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var ready = await UploadAndWaitAsync(alice, Fit(new FitSession(Start, 60)));
        var failed = await UploadAndWaitAsync(alice, Bytes("not a ride"), "note.txt");

        Assert.Equal(HttpStatusCode.NotFound, (await bob.GetAsync($"/api/v1/rides/{ready.Id}/laps", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await alice.GetAsync($"/api/v1/rides/{Guid.NewGuid()}/laps", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await alice.GetAsync($"/api/v1/rides/{failed.Id}/laps", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync($"/api/v1/rides/{ready.Id}/laps", Ct)).StatusCode);
    }

    [Fact]
    public async Task UploadRide_ShouldUseTheBikeForItsDimensions_WhenTheMemberHasSeveral()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var userId = (await member.GetFromJsonAsync<Server.Features.Accounts.MeResponse>("/api/v1/accounts/me", Ct))!.Id;

        Bike bike(string name, string kind, bool isDefault, int minute) => new()
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Name = name,
            Kind = kind,
            IsDefault = isDefault,
            IsActive = true,
            WheelCircumferenceMm = 2100,
            CreatedAt = DateTimeOffset.UtcNow.AddMinutes(minute),
        };
        var road = bike("Road", "road", isDefault: true, 1);
        var mountain = bike("Mountain", "mountain", isDefault: false, 2);
        var ebike = bike("E-bike", "ebike", isDefault: false, 3);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            db.Bikes.AddRange(road, mountain, ebike);
            await db.SaveChangesAsync(Ct);
        }

        var roadRide = await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(1), 60, SubSport: SubSport.Road)));
        var mountainRide = await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(2), 60, SubSport: SubSport.Mountain)));
        var ebikeRide = await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(3), 60, Sport.EBiking)));
        var indoorRide = await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddDays(4), 60, SubSport: SubSport.IndoorCycling)));

        Assert.Equal(road.Id, roadRide.BikeId);
        Assert.Equal(mountain.Id, mountainRide.BikeId);
        Assert.Equal(ebike.Id, ebikeRide.BikeId);
        Assert.Equal(road.Id, indoorRide.BikeId); // no kind for indoor: the single default
    }
}
