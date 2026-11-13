using System.IO.Compression;
using System.Net.Http.Json;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

/// <summary>What a Strava export leaves behind, and what it refuses to read.</summary>
public sealed class StravaImportArchiveTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static byte[] Zip(params (string Name, byte[] Body)[] entries)
    {
        using var stream = new MemoryStream();
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Create, leaveOpen: true))
        {
            foreach (var (name, body) in entries)
            {
                using var entry = zip.CreateEntry(name).Open();
                entry.Write(body);
            }
        }

        return stream.ToArray();
    }

    [Fact]
    public async Task StravaImport_ShouldDeleteTheArchive_WhenItHasFinished()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var archive = Zip(("activities.csv", Csv(("111", "Ride", "activities/111.gpx"))),
            ("activities/111.gpx", Bytes(Gpx(60))));

        var id = await StartAsync(member.Client, archive);
        await WaitAsync(member.Client, id);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var import = await db.RideImports.AsNoTracking().SingleAsync(i => i.Id == id, Ct);
        var store = scope.ServiceProvider.GetRequiredService<Velomine.Server.Features.Rides.Import.ImportStore>();
        await using var file = store.OpenRead(member.Id, import.ArchiveSha256);

        Assert.Null(file);
    }

    [Fact]
    public async Task StravaImport_ShouldIgnorePhotosAndOtherFiles_WhenTheArchiveHasThem()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var archive = Zip(
            ("activities.csv", Csv(("111", "Ride", "activities/111.gpx"))),
            ("activities/111.gpx", Bytes(Gpx(60))),
            ("activities/111.jpg", Bytes("not a photo")),
            ("media/ride.jpg", Bytes("another photo")),
            ("profile.csv", Bytes("name")));

        var id = await StartAsync(member.Client, archive);
        var done = await WaitAsync(member.Client, id);
        var rides = await member.Client.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);

        Assert.Equal("completed", done.Status);
        Assert.Single(rides!.Rides);
    }

    [Fact]
    public async Task StravaImport_ShouldRecordTheSourceAndActivityId_WhenTheRideIsBroughtIn()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var archive = Zip(("activities.csv", Csv(("20907461447", "Ride", "activities/20907461447.gpx"))),
            ("activities/20907461447.gpx", Bytes(Gpx(60))));

        var id = await StartAsync(member.Client, archive);
        await WaitAsync(member.Client, id);

        await using var scope = api.Services.CreateAsyncScope();
        var ride = await scope.ServiceProvider.GetRequiredService<VelomineDbContext>()
            .Rides.AsNoTracking().SingleAsync(r => r.UserId == member.Id, Ct);
        Assert.Equal("strava", ride.Source);
        Assert.Equal("20907461447", ride.SourceId);
    }

    [Fact]
    public async Task StravaImport_ShouldReadNoEntryOutsideTheArchive_WhenAnEntryNameClimbsOut()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        // The activity points outside the archive; the reader must not open it, and the import must survive.
        var archive = Zip(("activities.csv", Csv(("111", "Ride", "../../etc/passwd"))),
            ("activities/111.gpx", Bytes(Gpx(60))));

        var id = await StartAsync(member.Client, archive);
        var done = await WaitAsync(member.Client, id);

        Assert.Equal("completed", done.Status);
        Assert.Empty((await member.Client.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct))!.Rides);
    }

    private static byte[] Csv(params (string Id, string Name, string File)[] activities)
    {
        var text = new StringBuilder("Activity ID,Activity Date,Activity Name,Activity Type,Filename\n");
        foreach (var (id, name, file) in activities)
            text.Append($"{id},\"Oct 3, 2026\",\"{name}\",Ride,{file}\n");
        return Bytes(text.ToString());
    }

    private static async Task<Guid> StartAsync(HttpClient client, byte[] archive)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(archive), "file", "export.zip" } };
        var response = await client.PostAsync("/api/v1/rides/imports", form, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<StartRideImportResponse>(Ct))!.ImportId;
    }

    private static async Task<RideImportResponse> WaitAsync(HttpClient client, Guid id)
    {
        for (var i = 0; i < 1000; i++)
        {
            var import = await client.GetFromJsonAsync<RideImportResponse>($"/api/v1/rides/imports/{id}", Ct);
            if (import!.Status != "processing") return import;
            await Task.Delay(20, Ct);
        }

        throw new TimeoutException("The import was still processing after 20 seconds.");
    }
}
