using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Import;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

[Collection("postgres")]
public sealed class RideTitleTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<HttpClient> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return await api.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    private static async Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file, string name = "ride.gpx")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", name } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form, Ct);
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

    /// <summary>A GPX ride that is not named by its file, so the test decides the title.</summary>
    private static Task<RideResponse> UploadUnnamedAsync(HttpClient client, DateTime start) =>
        UploadAndWaitAsync(client, Bytes(Gpx(60, start: start, trackName: "")));

    private static Task<HttpResponseMessage> SetDetailsAsync(HttpClient client, Guid id, string? title, string? description, long version) =>
        client.PutAsJsonAsync($"/api/v1/rides/{id}/details", new SetRideDetailsRequest { Title = title, Description = description, Version = version }, Ct);

    private static async Task<RideResponse> NameAsync(HttpClient client, RideResponse ride, string? title, string? description = null)
    {
        var response = await SetDetailsAsync(client, ride.Id, title, description, ride.Version);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<RideResponse>(Ct))!;
    }

    private static async Task<ListRidesResponse> ListAsync(HttpClient client, string query = "") =>
        (await client.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides" + query, Ct))!;

    // --- Editing

    [Fact]
    public async Task SetRideDetails_ShouldSaveTrimmedText_WhenTheMemberNamesARide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadUnnamedAsync(member, Start);
        Assert.Null(ride.Title);

        var named = await NameAsync(member, ride, "  Dawn patrol  ", "  Cold start, warm finish.  ");

        Assert.Equal("Dawn patrol", named.Title);
        Assert.Equal("Cold start, warm finish.", named.Description);
        Assert.NotEqual(ride.Version, named.Version);
        var read = await member.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct);
        Assert.Equal("Dawn patrol", read!.Title);
        Assert.Equal("Cold start, warm finish.", read.Description);
    }

    [Fact]
    public async Task SetRideDetails_ShouldClearTheText_WhenOnlyWhitespaceIsSent()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var named = await NameAsync(member, await UploadUnnamedAsync(member, Start), "Dawn patrol", "Notes");

        var cleared = await NameAsync(member, named, "   ", "\n \t");

        Assert.Null(cleared.Title);
        Assert.Null(cleared.Description);
    }

    [Fact]
    public async Task SetRideDetails_ShouldRefuseTheText_WhenItIsTooLong()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadUnnamedAsync(member, Start);

        Assert.Equal(HttpStatusCode.BadRequest, (await SetDetailsAsync(member, ride.Id, new string('a', 121), null, ride.Version)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetDetailsAsync(member, ride.Id, null, new string('a', 2001), ride.Version)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await SetDetailsAsync(member, ride.Id, new string('a', 120), new string('b', 2000), ride.Version)).StatusCode);
    }

    [Fact]
    public async Task SetRideDetails_ShouldAnswerConflict_WhenTheRideChangedSinceItWasRead()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await UploadUnnamedAsync(member, Start);
        await NameAsync(member, ride, "First");

        var stale = await SetDetailsAsync(member, ride.Id, "Second", null, ride.Version);

        Assert.Equal(HttpStatusCode.Conflict, stale.StatusCode);
        Assert.Equal("First", (await member.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.Title);
    }

    [Fact]
    public async Task SetRideDetails_ShouldAnswerNotFound_WhenTheRideIsAnotherMembers()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        var ride = await UploadUnnamedAsync(alice, Start);

        Assert.Equal(HttpStatusCode.NotFound, (await SetDetailsAsync(bob, ride.Id, "Mine now", null, ride.Version)).StatusCode);
        Assert.Null((await alice.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.Title);
    }

    // --- Names from files

    [Fact]
    public async Task RideIngestion_ShouldUseTheTrackName_WhenTheFileHasOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var named = await UploadAndWaitAsync(member, Bytes(Gpx(60, trackName: "Passo Giau")));
        var unnamed = await UploadUnnamedAsync(member, Start.AddDays(1));

        Assert.Equal("Passo Giau", named.Title);
        Assert.Null(unnamed.Title);
    }

    [Fact]
    public void GpxParser_ShouldFallBackToTheFileName_WhenTheTrackHasNone()
    {
        var gpx = Gpx(5, trackName: "").Replace("<trk>", "<metadata><name>Sunday loop</name></metadata><trk>");

        Assert.Equal("Sunday loop", Assert.Single(RideFileParser.Parse(Bytes(gpx))).Title);
    }

    [Fact]
    public void GpxParser_ShouldCutALongName_WhenItIsLongerThanATitleMayBe()
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Gpx(5, trackName: new string('x', 300)))));

        Assert.Equal(120, ride.Title!.Length);
    }

    [Fact]
    public void TcxParser_ShouldUseTheFirstLineOfTheNote_WhenTheActivityHasOne()
    {
        var tcx = Tcx("Biking", 10).Replace("</Id>", "</Id><Notes>Lunch ride\nwith the club</Notes>");

        Assert.Equal("Lunch ride", Assert.Single(RideFileParser.Parse(Bytes(tcx))).Title);
    }

    [Fact]
    public void FitParser_ShouldUseTheWorkoutName_WhenTheFileFollowedAWorkout()
    {
        var ride = Assert.Single(RideFileParser.Parse(Fit(new FitSession(Start, 60, WorkoutName: "Sweet spot 2x20"))));

        Assert.Equal("Sweet spot 2x20", ride.Title);
        Assert.Null(Assert.Single(RideFileParser.Parse(Fit(new FitSession(Start, 60)))).Title);
    }

    // --- Search and dates

    [Fact]
    public async Task ListRides_ShouldFindRidesIgnoringCase_WhenSearchingTitleOrDescription()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var byTitle = await NameAsync(member, await UploadUnnamedAsync(member, Start), "Gravel with Marco");
        var byDescription = await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(1)), "Tuesday", "Rain all day, GRAVEL roads");
        await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(2)), "Road loop", "Dry");
        await UploadUnnamedAsync(member, Start.AddDays(3));

        var found = await ListAsync(member, "?q=gravel");

        Assert.Equal([byDescription.Id, byTitle.Id], found.Rides.Select(r => r.Id));
        Assert.Empty((await ListAsync(member, "?q=nothing-like-this")).Rides);
        Assert.Equal(4, (await ListAsync(member, "?q=")).Rides.Length);
        Assert.Equal(4, (await ListAsync(member, "?q=%20%20")).Rides.Length);
    }

    [Fact]
    public async Task ListRides_ShouldMatchWildcardsAsPlainText_WhenTheSearchHasPercentOrUnderscore()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var percent = await NameAsync(member, await UploadUnnamedAsync(member, Start), "100% effort");
        var underscore = await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(1)), "rest_day");
        await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(2)), "restful day");
        await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(3)), "Backslash \\ ride");

        Assert.Equal([percent.Id], (await ListAsync(member, "?q=" + Uri.EscapeDataString("%"))).Rides.Select(r => r.Id));
        Assert.Equal([underscore.Id], (await ListAsync(member, "?q=" + Uri.EscapeDataString("t_d"))).Rides.Select(r => r.Id));
        Assert.Single((await ListAsync(member, "?q=" + Uri.EscapeDataString("\\"))).Rides);
        Assert.Empty((await ListAsync(member, "?q=" + Uri.EscapeDataString("%%"))).Rides);
    }

    [Fact]
    public async Task ListRides_ShouldKeepEveryFilterAndTheCursorTogether_WhenSearchingWithADateRange()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var days = new[] { 1, 2, 3, 4, 5, 6 };
        var rides = new Dictionary<int, RideResponse>();
        foreach (var day in days)
            rides[day] = await NameAsync(member, await UploadUnnamedAsync(member, Start.AddDays(day - 3)), $"Ride {day} club");
        Assert.Equal(
            HttpStatusCode.OK,
            (await member.PutAsJsonAsync($"/api/v1/rides/{rides[3].Id}/type", new SetRideTypeRequest { Discipline = "gravel" }, Ct)).StatusCode);

        // Start is 3 October, so days 1 to 6 are 1 to 6 October. The range 2 to 5 October holds days 2 to 5; days 1 and 6
        // sit in the day either side that the database filter lets through and the exact cut then removes.
        const string range = "from=2026-10-02&to=2026-10-05&q=club";
        var first = await ListAsync(member, $"?{range}&limit=2");
        Assert.Equal([rides[5].Id, rides[4].Id], first.Rides.Select(r => r.Id));
        Assert.NotNull(first.Next);
        var second = await ListAsync(member, $"?{range}&limit=2&cursor={Uri.EscapeDataString(first.Next)}");
        Assert.Equal([rides[3].Id, rides[2].Id], second.Rides.Select(r => r.Id));
        Assert.Null(second.Next);

        // One ride per page still reaches the end, even though the rides on the edges are cut.
        var seen = new List<Guid>();
        string? cursor = null;
        do
        {
            var page = await ListAsync(member, $"?{range}&limit=1" + (cursor is null ? "" : $"&cursor={Uri.EscapeDataString(cursor)}"));
            seen.AddRange(page.Rides.Select(r => r.Id));
            cursor = page.Next;
        }
        while (cursor is not null);
        Assert.Equal([rides[5].Id, rides[4].Id, rides[3].Id, rides[2].Id], seen);

        var gravel = await ListAsync(member, $"?{range}&discipline=gravel");
        Assert.Equal([rides[3].Id], gravel.Rides.Select(r => r.Id));
        Assert.Empty((await ListAsync(member, $"?{range}&discipline=road")).Rides);
    }

    [Fact]
    public async Task ListRides_ShouldIncludeBothEndDays_WhenTheRangeIsInclusive()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var late = await UploadUnnamedAsync(member, new DateTime(2026, 10, 3, 23, 59, 0, DateTimeKind.Utc));
        var early = await UploadUnnamedAsync(member, new DateTime(2026, 10, 3, 0, 1, 0, DateTimeKind.Utc));
        await UploadUnnamedAsync(member, new DateTime(2026, 10, 4, 0, 30, 0, DateTimeKind.Utc));
        await UploadUnnamedAsync(member, new DateTime(2026, 10, 2, 22, 59, 0, DateTimeKind.Utc));

        var day = await ListAsync(member, "?from=2026-10-03&to=2026-10-03");

        Assert.Equal([late.Id, early.Id], day.Rides.Select(r => r.Id));
        Assert.Equal(3, (await ListAsync(member, "?to=2026-10-03")).Rides.Length);
        Assert.Single((await ListAsync(member, "?from=2026-10-04")).Rides);
    }

    [Fact]
    public async Task ListRides_ShouldUseTheMembersCalendar_WhenFilteringByDate()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        (await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Rider", null, null, null, "Pacific/Auckland", "monday"), Ct))
            .EnsureSuccessStatusCode();
        // 3 October 20:00 UTC is already 4 October in Auckland.
        var ride = await UploadUnnamedAsync(member, new DateTime(2026, 10, 3, 20, 0, 0, DateTimeKind.Utc));

        Assert.Equal([ride.Id], (await ListAsync(member, "?from=2026-10-04&to=2026-10-04")).Rides.Select(r => r.Id));
        Assert.Empty((await ListAsync(member, "?from=2026-10-03&to=2026-10-03")).Rides);
    }

    [Fact]
    public async Task ListRides_ShouldRefuseTheRequest_WhenADateOrTheSearchIsNotValid()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync("/api/v1/rides?from=yesterday", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync("/api/v1/rides?to=2026-13-01", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync("/api/v1/rides?q=" + new string('a', 101), Ct)).StatusCode);
    }

    [Fact]
    public async Task ListRides_ShouldNotSearchOtherMembersRides_WhenTheWordIsInTheirTitle()
    {
        await using var api = await StartAsync();
        var alice = await NewMemberAsync(api);
        var bob = await NewMemberAsync(api);
        await NameAsync(alice, await UploadUnnamedAsync(alice, Start), "Secret route");

        Assert.Empty((await ListAsync(bob, "?q=secret")).Rides);
    }

    // --- Strava import

    private static byte[] Export(params (string Id, string Name, string Description, string File, byte[] Content)[] activities)
    {
        static string Quote(string text) => "\"" + text.Replace("\"", "\"\"") + "\"";
        var csv = new StringBuilder("Activity ID,Activity Date,Activity Name,Activity Type,Activity Description,Filename\n");
        foreach (var (id, name, description, file, _) in activities)
            csv.Append($"{id},\"Oct 3, 2026, 8:00:00 AM\",{Quote(name)},Ride,{Quote(description)},{file}\n");

        var entries = new List<(string, byte[])> { (StravaExport.CsvEntry, Encoding.UTF8.GetBytes(csv.ToString())) };
        entries.AddRange(activities.Select(a => (a.File, a.Content)));
        return Zip([.. entries]);
    }

    private static async Task ImportAsync(HttpClient client, byte[] archive)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(archive), "file", "export.zip" } };
        var started = await client.PostAsync("/api/v1/rides/imports", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, started.StatusCode);
        var id = (await started.Content.ReadFromJsonAsync<StartRideImportResponse>(Ct))!.ImportId;
        for (var i = 0; i < 200; i++)
        {
            var import = await client.GetFromJsonAsync<RideImportResponse>($"/api/v1/rides/imports/{id}", Ct);
            if (import!.Status != "processing") return;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The import was still processing after 20 seconds.");
    }

    [Fact]
    public async Task StravaImport_ShouldBringNamesAndDescriptions_WhenTheArchiveHasThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await ImportAsync(member, Export(("111", "Morning ride", "Frosty, \"quiet\" roads", "activities/111.gpx", Bytes(Gpx(60, trackName: "")))));

        var ride = Assert.Single((await ListAsync(member)).Rides);
        Assert.Equal("Morning ride", ride.Title);
        Assert.Equal("Frosty, \"quiet\" roads", ride.Description);
    }

    [Fact]
    public async Task StravaImport_ShouldPreferTheArchivesName_WhenTheFileHasAnotherOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await ImportAsync(member, Export(("111", "Name from Strava", "", "activities/111.gpx", Bytes(Gpx(60, trackName: "Name from the file")))));

        Assert.Equal("Name from Strava", Assert.Single((await ListAsync(member)).Rides).Title);
    }

    [Fact]
    public async Task StravaImport_ShouldFillOnlyEmptyText_WhenALaterExportMeetsARideThatIsHere()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var gpx = Bytes(Gpx(60, trackName: ""));
        await ImportAsync(member, Export(("111", "", "", "activities/111.gpx", gpx), ("222", "", "", "activities/222.gpx", Bytes(Gpx(60, start: Start.AddDays(1), trackName: "")))));
        var rides = (await ListAsync(member)).Rides;
        var first = rides.Single(r => r.FileName == "111.gpx");
        var second = rides.Single(r => r.FileName == "222.gpx");
        Assert.Null(first.Title);
        await NameAsync(member, second, "Mine", "My words");

        await ImportAsync(member, Export(
            ("111", "Strava name", "Strava words", "activities/111.gpx", gpx),
            ("222", "Strava name too", "Strava words too", "activities/222.gpx", Bytes(Gpx(60, start: Start.AddDays(1), trackName: "")))));

        var after = (await ListAsync(member)).Rides;
        Assert.Equal(2, after.Length);
        var filled = after.Single(r => r.Id == first.Id);
        Assert.Equal("Strava name", filled.Title);
        Assert.Equal("Strava words", filled.Description);
        var kept = after.Single(r => r.Id == second.Id);
        Assert.Equal("Mine", kept.Title);
        Assert.Equal("My words", kept.Description);
    }

    // --- Export and deletion

    [Fact]
    public async Task AccountExport_ShouldHoldTitleAndDescription_WhenARideHasThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await NameAsync(member, await UploadUnnamedAsync(member, Start), "Dawn patrol", "Cold start");

        var link = (await (await member.PostAsync("/api/v1/accounts/me/export-link", null, Ct)).Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();
        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var reader = new StreamReader(zip.GetEntry("rides.json")!.Open());
        var rides = JsonDocument.Parse(await reader.ReadToEndAsync(Ct)).RootElement;

        var ride = rides[0].GetProperty("ride");
        Assert.Equal("Dawn patrol", ride.GetProperty("title").GetString());
        Assert.Equal("Cold start", ride.GetProperty("description").GetString());
    }

    [Fact]
    public async Task DeleteRide_ShouldTakeTheTextWithIt_WhenTheRideIsDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var ride = await NameAsync(member, await UploadUnnamedAsync(member, Start), "Dawn patrol", "Cold start");

        (await member.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).EnsureSuccessStatusCode();

        Assert.Empty((await ListAsync(member, "?q=dawn")).Rides);
        Assert.Equal(HttpStatusCode.NotFound, (await member.GetAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);
    }
}
