using System.Net;
using System.Net.Http.Json;
using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Import;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

public sealed class StravaImportTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            more?.Invoke(b);
        });

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    /// <summary>
    /// A Strava export with Italian column names and a quoted field holding a comma, as the real archive has: the
    /// reader must not depend on the language or on naive splitting.
    /// </summary>
    private static byte[] Export(params (string Id, string File, byte[] Content)[] activities)
    {
        var csv = new StringBuilder("ID attività,Data dell’attività,Nome attività,Tipo attività,Tragitto pendolare,Nome del file\n");
        foreach (var (id, file, _) in activities)
            csv.Append($"{id},\"8 nov 2026, 10:33:07\",\"Giro, con virgola\",Ciclismo,false,{file}\n");

        var entries = new List<(string, byte[])> { (StravaExport.CsvEntry, Encoding.UTF8.GetBytes('\uFEFF' + csv.ToString())) };
        entries.AddRange(activities.Where(a => a.File.Length > 0).Select(a => (a.File, a.Content)));
        return Zip([.. entries]);
    }

    private static async Task<Guid> StartImportAsync(HttpClient client, byte[] archive, string name = "export_166520172.zip")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(archive), "file", name } };
        var response = await client.PostAsync("/api/v1/rides/imports", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<StartRideImportResponse>(Ct))!.ImportId;
    }

    private static async Task<RideImportResponse> WaitImportAsync(HttpClient client, Guid id)
    {
        for (var i = 0; i < 200; i++)
        {
            var import = await client.GetFromJsonAsync<RideImportResponse>($"/api/v1/rides/imports/{id}", Ct);
            if (import!.Status != "processing") return import;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The import was still processing after 20 seconds.");
    }

    private static Task<HttpResponseMessage> UploadAsync(HttpClient client, byte[] file, string name = "ride.gpx") =>
        client.PostAsync("/api/v1/rides/uploads", new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } }, Ct);

    private static async Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file, string name = "ride.gpx", string? key = null)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/rides/uploads") { Content = form };
        if (key is not null) request.Headers.Add("Idempotency-Key", key);
        var accepted = await client.SendAsync(request, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            var ride = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct);
            if (ride!.Status != "processing") return ride;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

    [Fact]
    public async Task StravaImport_ShouldCreateReadyRides_WhenTheArchiveHasCyclingActivities()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(
            ("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))),
            ("222", "activities/222.gpx", Bytes(Gpx(120, start: Start.AddDays(1)))));

        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal("completed", import.Status);
        Assert.Equal(2, import.Total);
        Assert.Equal(2, import.Imported);
        Assert.Equal(0, import.Skipped);
        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        Assert.Equal(2, list!.Rides.Length);
        Assert.All(list.Rides, r => Assert.Equal("ready", r.Status));
        Assert.Contains(list.Rides, r => r.FileName == "111.gpx");
    }

    [Fact]
    public async Task StravaImport_ShouldCountOtherSportsAsSkipped_WhenTheArchiveHasARun()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(("111", "activities/111.gpx", Bytes(Gpx(60, type: "running"))));

        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(1, import.Total);
        Assert.Equal(0, import.Imported);
        Assert.Equal(1, import.Skipped);
        Assert.Empty((await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
    }

    [Fact]
    public async Task StravaImport_ShouldCountActivitiesWithoutAFile_WhenTheExportHasManualEntries()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(
            ("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))),
            ("222", "", []));

        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(2, import.Total);
        Assert.Equal(1, import.Imported);
        Assert.Equal(1, import.Skipped);
    }

    [Fact]
    public async Task StravaImport_ShouldReadGzippedActivityFiles_WhenTheExportHasThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(("111", "activities/111.gpx.gz", Gzip(Bytes(Gpx(60, start: Start)))));

        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(1, import.Imported);
    }

    [Fact]
    public async Task StravaImport_ShouldReturnTheSameImport_WhenTheSameArchiveIsUploadedAgain()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))));

        var first = await StartImportAsync(member, archive);
        await WaitImportAsync(member, first);
        var again = await StartImportAsync(member, archive);
        var import = await WaitImportAsync(member, again);

        Assert.Equal(first, again);
        Assert.Equal(1, import.Imported);
        Assert.Single((await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
    }

    [Fact]
    public async Task StravaImport_ShouldSkipAnActivity_WhenANewerExportListsOneAlreadyHere()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var older = Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))));
        await WaitImportAsync(member, await StartImportAsync(member, older));

        // The same activity in a later export, with a re-encoded file, must not become a second ride.
        var newer = Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start.AddDays(3)))));
        var import = await WaitImportAsync(member, await StartImportAsync(member, newer));

        Assert.Equal(0, import.Imported);
        Assert.Equal(1, import.Skipped);
        Assert.Single((await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
    }

    [Fact]
    public async Task StravaImport_ShouldHideTheCopy_WhenAnotherAppRecordedTheSameRide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var here = await UploadAndWaitAsync(member, Bytes(Gpx(60, start: Start, trackName: "Recorded here")));

        var archive = Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start, trackName: "From Strava"))));
        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(0, import.Imported);
        Assert.Equal(1, import.Duplicates);
        var visible = Assert.Single((await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
        Assert.Equal(here.Id, visible.Id);
    }

    [Fact]
    public async Task StravaImport_ShouldKeepBoth_WhenASimilarRideStartedAtAnotherTime()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await UploadAndWaitAsync(member, Bytes(Gpx(60, start: Start, trackName: "First")));

        var archive = Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start.AddMinutes(10), trackName: "Later"))));
        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(1, import.Imported);
        Assert.Equal(2, (await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides.Length);
    }

    [Fact]
    public async Task StravaImport_ShouldSendOneNotification_WhenItFinishes()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var userId = (await member.GetFromJsonAsync<Server.Features.Accounts.MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        var archive = Export(
            ("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))),
            ("222", "activities/222.gpx", Bytes(Gpx(90, start: Start.AddDays(1)))),
            // A file that cannot be read stays as a failed ride, so its notification would survive if one were sent.
            ("333", "activities/333.gpx", Bytes("not a ride")));

        await WaitImportAsync(member, await StartImportAsync(member, archive));

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var types = await db.Notifications.AsNoTracking().Where(n => n.UserId == userId).Select(n => n.Type).ToListAsync(Ct);
        Assert.Equal(["ride_import"], types);
    }

    [Fact]
    public async Task StravaImport_ShouldReportAndHideAnUnreadableFile_WhenTheArchiveHasOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Export(
            ("111", "activities/111.gpx", Bytes(Gpx(60, start: Start))),
            ("222", "activities/222.gpx", Bytes("not a ride")));

        var import = await WaitImportAsync(member, await StartImportAsync(member, archive));

        Assert.Equal(1, import.Failed);
        var list = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        Assert.Equal("111.gpx", Assert.Single(list!.Rides).FileName);
    }

    [Fact]
    public async Task StravaImport_ShouldBeInvisibleToAnotherMember_WhenItIsNotTheirs()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var id = await StartImportAsync(alice, Export(("111", "activities/111.gpx", Bytes(Gpx(60, start: Start)))));
        await WaitImportAsync(alice, id);

        Assert.Equal(HttpStatusCode.NotFound, (await bob.GetAsync($"/api/v1/rides/imports/{id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await bob.GetAsync($"/api/v1/rides/imports/{Guid.NewGuid()}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync($"/api/v1/rides/imports/{id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task StravaImport_ShouldRejectTheArchive_WhenItIsNotAZip()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var response = await member.PostAsync("/api/v1/rides/imports",
            new MultipartFormDataContent { { new ByteArrayContent(Bytes("not an archive")), "file", "export.zip" } }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task StravaImport_ShouldRejectTheArchive_WhenItHasNoActivitiesCsv()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var archive = Zip(("profile.csv", Bytes("name")));

        var response = await member.PostAsync("/api/v1/rides/imports",
            new MultipartFormDataContent { { new ByteArrayContent(archive), "file", "export.zip" } }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

}
