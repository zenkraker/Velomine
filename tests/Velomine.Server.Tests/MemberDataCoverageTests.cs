using System.IO.Compression;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Import;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests;

/// <summary>
/// A new table that holds member data must join the export and the deletion in the same change. This walks the model
/// rather than a hand-written list, so a table added later fails here instead of quietly escaping both.
/// </summary>
public sealed class MemberDataCoverageTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Every entity with a member's id, and the export file that carries it.</summary>
    private static readonly Dictionary<string, string> ExportFiles = new()
    {
        ["Ride"] = "rides.json",
        ["RideImport"] = "imports.json",
        ["Bike"] = "bikes.json",
        ["BikeTemplate"] = "templates.json",
        ["Goal"] = "goals.json",
        ["Notification"] = "notifications.json",
        ["UserSession"] = "sessions.json",
        ["DailyCheckIn"] = "wellbeing.json",
        ["PrivacySettings"] = "privacy.json",
        ["PrivacyZone"] = "privacy.json",
        ["CyclingRoute"] = "routes.json",
        ["ClubMembership"] = "clubs.json",
        ["Licence"] = "supporter.json",
        ["CalendarFeed"] = "clubs.json",
        ["ClubJoinRequest"] = "clubs.json",
        ["RideSignUp"] = "club-rides.json",
    };

    [Fact]
    public async Task EveryMemberTable_ShouldBeInTheExport_WhenTheMemberAsksForTheirData()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();

        // One row in each table that belongs to the member alone.
        var bikeId = await AddBikeAsync(member.Client, member.Id);
        (await member.Client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", new CreateComponentRequest
        {
            Type = "chain",
            Brand = "Shimano",
            Model = "Ultegra",
            Mpn = "CN-M8100",
            InstalledOn = new DateOnly(2026, 1, 1),
        }, Ct)).EnsureSuccessStatusCode();
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 120)));
        var rideId = (await RideIdsAsync(member.Client))[0];
        await member.Client.PostAsJsonAsync("/api/v1/wellbeing/consent", new { Version = 1 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/wellbeing/check-ins/today", new { Fatigue = 3, Mood = 3, Rpe = 3, Notes = "ok" }, Ct);
        await member.Client.PutAsJsonAsync($"/api/v1/rides/{rideId}/feel", new { Feel = "good" }, Ct);
        await member.Client.PutAsJsonAsync("/api/v1/privacy/settings", new UpdatePrivacyRequest { HideHeartRate = false, HidePower = false, HideCadence = false, HideSpeed = false, HideElevation = false, HideTemperature = false, TrimStartM = 0, TrimEndM = 0 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/privacy/zones",
            new CreatePrivacyZoneRequest { Name = "Home", Latitude = 46, Longitude = 11, RadiusM = 500 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/analytics/goals", new { Period = "week", Metric = "distance", Target = 100000.0 }, Ct);
        await member.Client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates", new SaveBikeAsTemplateRequest { BikeId = bikeId, Name = "Mine" }, Ct);
        await member.Client.GetAsync("/api/v1/notifications", Ct);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var exporters = new Dictionary<string, Func<VelomineDbContext, Guid, Task<int>>>
        {
            ["Ride"] = (context, id) => context.Rides.CountAsync(r => r.UserId == id, Ct),
            ["RideImport"] = (context, id) => context.RideImports.CountAsync(r => r.UserId == id, Ct),
            ["Bike"] = (context, id) => context.Bikes.CountAsync(r => r.UserId == id, Ct),
            ["BikeTemplate"] = (context, id) => context.BikeTemplates.CountAsync(r => r.UserId == id, Ct),
            ["Goal"] = (context, id) => context.Goals.CountAsync(r => r.UserId == id, Ct),
            ["Notification"] = (context, id) => context.Notifications.CountAsync(r => r.UserId == id, Ct),
            ["UserSession"] = (context, id) => context.UserSessions.CountAsync(r => r.UserId == id, Ct),
            ["DailyCheckIn"] = (context, id) => context.DailyCheckIns.CountAsync(r => r.UserId == id, Ct),
            ["PrivacySettings"] = (context, id) => context.PrivacySettings.CountAsync(r => r.UserId == id, Ct),
            ["PrivacyZone"] = (context, id) => context.PrivacyZones.CountAsync(r => r.UserId == id, Ct),
            ["CyclingRoute"] = (context, id) => context.Routes.CountAsync(r => r.UserId == id, Ct),
            ["ClubMembership"] = (context, id) => context.ClubMemberships.CountAsync(m => m.UserId == id, Ct),
            ["Licence"] = (context, id) => context.SupporterLicences.CountAsync(l => l.UserId == id, Ct),
            ["CalendarFeed"] = (context, id) => context.CalendarFeeds.CountAsync(f => f.UserId == id, Ct),
            ["ClubJoinRequest"] = (context, id) => context.ClubJoinRequests.CountAsync(r => r.UserId == id, Ct),
            ["RideSignUp"] = (context, id) => context.RideSignUps.CountAsync(s => s.UserId == id, Ct),
        };

        // Every table the model gives a member's id must be handled here; a new one fails this line.
        var memberTables = db.Model.GetEntityTypes()
            .Where(e => e.ClrType.GetProperty("UserId") is { PropertyType: var type }
                && (type == typeof(Guid) || type == typeof(Guid?))
                // Identity's own link tables (claims, logins, roles, tokens) cascade with the user row in the framework.
                && !e.ClrType.Namespace!.StartsWith("Microsoft.AspNetCore.Identity", StringComparison.Ordinal))
            .Select(e => e.ClrType.Name)
            .Order()
            .ToList();
        Assert.Equal(ExportFiles.Keys.Order(), memberTables);
        Assert.Equal(memberTables, exporters.Keys.Order());

        using var stream = new MemoryStream();
        await ActivatorUtilities.CreateInstance<AccountExport>(scope.ServiceProvider).WriteAsync(member.Id, stream, Ct);
        stream.Position = 0;
        using var zip = new ZipArchive(stream);

        foreach (var (entity, file) in ExportFiles)
            Assert.True(zip.GetEntry(file) is not null, $"{entity} holds member data but {file} is missing from the export.");

        // The export carries the rows the test wrote.
        Assert.True(await db.BikeTemplates.AnyAsync(t => t.UserId == member.Id, Ct), "the template was not saved");
        Assert.True(await db.PrivacyZones.AnyAsync(z => z.UserId == member.Id, Ct), "the privacy zone was not saved");
    }

    [Fact]
    public async Task AccountDeletion_ShouldEmptyEveryMemberTable_WhenTheMemberLeaves()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var bikeId = await AddBikeAsync(member.Client, member.Id);
        (await member.Client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", new CreateComponentRequest
        {
            Type = "chain",
            Brand = "Shimano",
            Model = "Ultegra",
            Mpn = "CN-M8100",
            InstalledOn = new DateOnly(2026, 1, 1),
        }, Ct)).EnsureSuccessStatusCode();
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 120)));
        var rideId = (await RideIdsAsync(member.Client))[0];
        await member.Client.PostAsJsonAsync("/api/v1/wellbeing/consent", new { Version = 1 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/wellbeing/check-ins/today", new { Fatigue = 3, Mood = 3, Rpe = 3, Notes = "ok" }, Ct);
        await member.Client.PutAsJsonAsync($"/api/v1/rides/{rideId}/feel", new { Feel = "good" }, Ct);
        await member.Client.PutAsJsonAsync("/api/v1/privacy/settings", new UpdatePrivacyRequest { HideHeartRate = false, HidePower = false, HideCadence = false, HideSpeed = false, HideElevation = false, HideTemperature = false, TrimStartM = 0, TrimEndM = 0 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/privacy/zones",
            new CreatePrivacyZoneRequest { Name = "Home", Latitude = 46, Longitude = 11, RadiusM = 500 }, Ct);
        await member.Client.PostAsJsonAsync("/api/v1/analytics/goals", new { Period = "week", Metric = "distance", Target = 100000.0 }, Ct);
        await member.Client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates", new SaveBikeAsTemplateRequest { BikeId = bikeId, Name = "Mine" }, Ct);

        await member.Client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var counts = new Dictionary<string, int>
        {
            ["Ride"] = await db.Rides.CountAsync(r => r.UserId == member.Id, Ct),
            ["RideImport"] = await db.RideImports.CountAsync(r => r.UserId == member.Id, Ct),
            ["Bike"] = await db.Bikes.CountAsync(r => r.UserId == member.Id, Ct),
            ["BikeTemplate"] = await db.BikeTemplates.CountAsync(r => r.UserId == member.Id, Ct),
            ["Goal"] = await db.Goals.CountAsync(r => r.UserId == member.Id, Ct),
            ["Notification"] = await db.Notifications.CountAsync(r => r.UserId == member.Id, Ct),
            ["UserSession"] = await db.UserSessions.CountAsync(r => r.UserId == member.Id, Ct),
            ["DailyCheckIn"] = await db.DailyCheckIns.CountAsync(r => r.UserId == member.Id, Ct),
            ["PrivacySettings"] = await db.PrivacySettings.CountAsync(r => r.UserId == member.Id, Ct),
            ["PrivacyZone"] = await db.PrivacyZones.CountAsync(r => r.UserId == member.Id, Ct),
            ["CyclingRoute"] = await db.Routes.CountAsync(r => r.UserId == member.Id, Ct),
            ["ClubMembership"] = await db.ClubMemberships.CountAsync(m => m.UserId == member.Id, Ct),
            ["Licence"] = await db.SupporterLicences.CountAsync(l => l.UserId == member.Id, Ct),
            ["CalendarFeed"] = await db.CalendarFeeds.CountAsync(f => f.UserId == member.Id, Ct),
            ["ClubJoinRequest"] = await db.ClubJoinRequests.CountAsync(r => r.UserId == member.Id, Ct),
            ["RideSignUp"] = await db.RideSignUps.CountAsync(s => s.UserId == member.Id, Ct),
        };
        Assert.Equal(ExportFiles.Keys.Order(), counts.Keys.Order());

        // A member with nothing in a table is fine; what must not survive is a row in a table that had one.
        Assert.Equal(0, counts["Bike"]);
        Assert.Equal(0, counts["BikeTemplate"]);
        Assert.Equal(0, counts["DailyCheckIn"]);
        Assert.Equal(0, counts["PrivacySettings"]);
        Assert.Equal(0, counts["PrivacyZone"]);
        Assert.Equal(0, counts["Ride"]);
        Assert.Equal(0, counts["UserSession"]);
        Assert.Equal(0, counts["Notification"]);
        Assert.Equal(0, counts["Goal"]);
    }

    private static async Task<Guid> AddBikeAsync(HttpClient client, Guid userId)
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static async Task<Guid[]> RideIdsAsync(HttpClient client)
    {
        var list = await client.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        return [.. list!.Rides.Select(r => r.Id)];
    }
}
