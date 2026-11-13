using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Bikes;

public sealed class MaintenanceTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    private static async Task<BikeDetailResponse> AddBikeAsync(HttpClient client, string kind = "road", double initialM = 0)
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes", new CreateBikeRequest { Name = "Road bike", Kind = kind, WheelCircumferenceMm = 2105, InitialDistanceM = initialM }, Ct);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!;
    }

    private static async Task<BikeDetailResponse> AddReminderAsync(HttpClient client, Guid bikeId, CreateReminderRequest request)
    {
        var response = await client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/reminders", request, Ct);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!;
    }

    private static CreateReminderRequest LubeChain(string lastDone = "2026-10-01") =>
        new() { Name = "Lube the chain", IntervalDistanceM = 300_000, LastDoneOn = DateOnly.Parse(lastDone) };

    /// <summary>Saves a finished ride straight into the database, as if it had been uploaded and read.</summary>
    private static async Task AddRideAsync(TestApi api, Guid userId, Guid bikeId, string startUtc, double km, double hours = 1, int? offsetMinutes = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            BikeId = bikeId,
            Status = RideStatus.Ready,
            FileSha256 = Guid.NewGuid().ToString("N"),
            FileName = "ride.fit",
            UploadedAt = Now,
            StartTime = DateTimeOffset.Parse(startUtc + "Z"),
            UtcOffsetMinutes = offsetMinutes,
            DistanceM = km * 1000,
            MovingS = hours * 3600,
        });
        await db.SaveChangesAsync(Ct);
    }

    private static async Task<ListServiceEntriesResponse> LogAsync(HttpClient client, Guid bikeId, string query = "") =>
        (await client.GetFromJsonAsync<ListServiceEntriesResponse>($"/api/v1/bikes/{bikeId}/service{query}", Ct))!;

    private static async Task<ListNotificationsResponse> NotificationsAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!;

    private static string[] ReminderTypes(ListNotificationsResponse list) =>
        [.. list.Notifications.Select(n => n.Type).Where(t => t.StartsWith("reminder_", StringComparison.Ordinal))];

    /// <summary>The reminder notifications, waiting until there are <paramref name="expected"/> of them: the ride is
    /// marked ready just before the wear and reminder checks write theirs.</summary>
    private static async Task<string[]> ReminderTypesAsync(HttpClient client, int expected)
    {
        string[] types = [];
        for (var i = 0; i < 100; i++)
        {
            types = ReminderTypes(await NotificationsAsync(client));
            if (types.Length >= expected) return types;
            await Task.Delay(100, Ct);
        }
        return types;
    }

    private static Task SweepAsync(TestApi api) =>
        new MaintenanceReminderService(api.Services.GetRequiredService<IServiceScopeFactory>(), NullLogger<MaintenanceReminderService>.Instance).RunOnceAsync(Ct);

    [Fact]
    public async Task Reminders_ShouldShowProgressFromTheRides_WhenRidesFollowTheDoneDay()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-09-30T08:00:00", 100); // before the done day: the last cycle's
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 210, hours: 7);

        var detail = await AddReminderAsync(member, bike.Bike.Id, LubeChain());

        var reminder = Assert.Single(detail.Reminders);
        Assert.Equal(210_000, reminder.UsedDistanceM);
        Assert.Equal(7, reminder.UsedHours);
        Assert.Equal(70, reminder.Percent);
        Assert.Equal("ok", reminder.Status);
        Assert.Equal(new DateOnly(2026, 10, 1), reminder.LastDoneOn);
    }

    [Fact]
    public async Task Reminders_ShouldCountTheRidesOnTheMembersCalendar_WhenTheRideStartedNearMidnight()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        // 23:30 UTC on 30 September is already 1 October in Rome (UTC+2); the file says so.
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-09-30T23:30:00", 80, offsetMinutes: 120);
        // 23:30 UTC on 1 October is 2 October there, and a ride abroad (UTC-5) is still 1 October.
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-01T23:30:00", 20, offsetMinutes: -300);

        var detail = await AddReminderAsync(member, bike.Bike.Id, LubeChain("2026-10-01"));

        Assert.Equal(100_000, Assert.Single(detail.Reminders).UsedDistanceM);
    }

    [Fact]
    public async Task Reminders_ShouldRestartTheCountAndWriteTheLog_WhenMarkedDone()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, initialM: 4_000_000);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 250);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-20T08:00:00", 62);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest { DoneOn = new DateOnly(2026, 10, 10) }, Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var reminder = Assert.Single((await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Reminders);
        Assert.Equal(new DateOnly(2026, 10, 10), reminder.LastDoneOn);
        Assert.Equal(62_000, reminder.UsedDistanceM); // only the ride after the done day
        var entry = Assert.Single((await LogAsync(member, bike.Bike.Id)).Entries);
        Assert.Equal("Lube the chain", entry.Title);
        Assert.Equal(ServiceOrigins.Reminder, entry.Origin);
        Assert.Equal(reminderId, entry.ReminderId);
        Assert.Equal(new DateOnly(2026, 10, 10), entry.Date);
        Assert.Equal(4_250_000, entry.BikeDistanceM); // the ride of 20 October is after that date
    }

    [Fact]
    public async Task Reminders_ShouldRefuseAFutureDay_WhenMarkedDoneOrCreated()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;

        var done = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest { DoneOn = new DateOnly(2026, 11, 5) }, Ct);
        var created = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders", LubeChain("2026-11-05"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, done.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, created.StatusCode);
        Assert.Empty((await LogAsync(member, bike.Bike.Id)).Entries);
    }

    [Theory]
    [InlineData("", 300_000.0, null, null)]
    [InlineData("Lube", null, null, null)]
    [InlineData("Lube", 0.0, null, null)]
    [InlineData("Lube", null, -1.0, null)]
    [InlineData("Lube", null, null, 0)]
    public async Task Reminders_ShouldBeRefused_WhenTheNameOrIntervalsAreInvalid(string name, double? distance, double? hours, int? months)
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders",
            new CreateReminderRequest { Name = name, IntervalDistanceM = distance, IntervalHours = hours, IntervalMonths = months }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Reminders_ShouldBeEditedPausedAndDeleted_WhenManagedByTheOwner()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;

        var edit = new UpdateReminderRequest { Name = "Wax the chain", IntervalDistanceM = 500_000, IntervalMonths = 6, IsPaused = true };
        var edited = Assert.Single((await (await member.PutAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}", edit, Ct))
            .Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Reminders);
        Assert.Equal("Wax the chain", edited.Name);
        Assert.Equal(6, edited.IntervalMonths);
        Assert.Equal("paused", edited.Status);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}", Ct)).StatusCode);
        Assert.Empty((await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{bike.Bike.Id}", Ct))!.Reminders);
        Assert.Equal(HttpStatusCode.NotFound, (await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}", Ct)).StatusCode);
    }

    [Fact]
    public async Task Reminders_ShouldListTheMostUrgentFirst_WhenSeveralExist()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 250);
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Fine", IntervalDistanceM = 1_000_000, LastDoneOn = new DateOnly(2026, 10, 1) });
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Due", IntervalDistanceM = 100_000, LastDoneOn = new DateOnly(2026, 10, 1) });
        var detail = await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Soon", IntervalDistanceM = 300_000, LastDoneOn = new DateOnly(2026, 10, 1) });

        Assert.Equal(["Due", "Soon", "Fine"], detail.Reminders.Select(r => r.Name));
    }

    [Fact]
    public async Task Reminders_ShouldMarkTheBikeInTheList_WhenSomethingIsDueOrNearlyDue()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 250);
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Due", IntervalDistanceM = 100_000, LastDoneOn = new DateOnly(2026, 10, 1) });
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Soon", IntervalDistanceM = 300_000, LastDoneOn = new DateOnly(2026, 10, 1) });
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Paused", IntervalDistanceM = 100_000, LastDoneOn = new DateOnly(2026, 10, 1) });
        var paused = (await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{bike.Bike.Id}", Ct))!.Reminders.Single(r => r.Name == "Paused");
        await member.PutAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{paused.Id}",
            new UpdateReminderRequest { Name = "Paused", IntervalDistanceM = 100_000, IsPaused = true }, Ct);

        var listed = Assert.Single((await member.GetFromJsonAsync<ListBikesResponse>("/api/v1/bikes", Ct))!.Bikes);

        Assert.Equal(1, listed.ServiceDueCount);
        Assert.Equal(1, listed.ServiceSoonCount);
    }

    [Fact]
    public async Task Reminders_ShouldWarnOncePerLevel_WhenRidesTakeThemToSoonAndDue()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        // Each test ride is 952 m, so a 1 km job is "soon" after one ride and due after two.
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Lube the chain", IntervalDistanceM = 1000, LastDoneOn = new DateOnly(2026, 10, 1) });

        await UploadAndWaitAsync(member, Fit(new FitSession(Start, 120)));
        Assert.Equal(["reminder_soon"], await ReminderTypesAsync(member, 1));

        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddHours(3), 120)));
        await UploadAndWaitAsync(member, Fit(new FitSession(Start.AddHours(6), 120)));

        Assert.Equal(["reminder_due", "reminder_soon"], await ReminderTypesAsync(member, 2));
        var due = (await NotificationsAsync(member)).Notifications.First(n => n.Type == NotificationTypes.ReminderDue);
        Assert.Equal("Lube the chain on Road bike", due.Subject);
        Assert.Equal(bike.Bike.Id, due.BikeId);
    }

    [Fact]
    public async Task Reminders_ShouldWarnAgain_WhenMarkedDoneAndWornAgain()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 400);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;
        await SweepAsync(api);
        await SweepAsync(api);
        Assert.Equal(["reminder_due"], ReminderTypes(await NotificationsAsync(member)));

        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest { DoneOn = new DateOnly(2026, 10, 3) }, Ct);
        await SweepAsync(api);
        Assert.Equal(["reminder_due"], ReminderTypes(await NotificationsAsync(member))); // done: nothing new

        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-20T08:00:00", 310);
        await SweepAsync(api);
        Assert.Equal(["reminder_due", "reminder_due"], ReminderTypes(await NotificationsAsync(member)));
    }

    [Fact]
    public async Task Reminders_ShouldFireByMonths_WhenTheBikeIsNotRidden()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        // Last done on 1 July: four months ago, so a 3-month job is due; no ride ever happened.
        await AddReminderAsync(member, bike.Bike.Id, new CreateReminderRequest { Name = "Top up sealant", IntervalMonths = 3, LastDoneOn = new DateOnly(2026, 7, 1) });

        await SweepAsync(api);
        await SweepAsync(api);

        var list = await NotificationsAsync(member);
        Assert.Equal(["reminder_due"], ReminderTypes(list));
        Assert.Equal("Top up sealant on Road bike", list.Notifications.Single().Subject);
    }

    [Fact]
    public async Task Reminders_ShouldStayQuiet_WhenTheBikeIsArchivedOrTheReminderPaused()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var retired = await AddBikeAsync(member);
        var paused = await AddBikeAsync(member);
        var old = new CreateReminderRequest { Name = "Old job", IntervalMonths = 1, LastDoneOn = new DateOnly(2026, 1, 1) };
        await AddReminderAsync(member, retired.Bike.Id, old);
        var reminderId = Assert.Single((await AddReminderAsync(member, paused.Bike.Id, old)).Reminders).Id;
        await member.PutAsJsonAsync($"/api/v1/bikes/{retired.Bike.Id}",
            new UpdateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0, IsActive = false }, Ct);
        await member.PutAsJsonAsync($"/api/v1/bikes/{paused.Bike.Id}/reminders/{reminderId}",
            new UpdateReminderRequest { Name = "Old job", IntervalMonths = 1, IsPaused = true }, Ct);

        await SweepAsync(api);

        Assert.Empty(ReminderTypes(await NotificationsAsync(member)));
        var listed = (await member.GetFromJsonAsync<ListBikesResponse>("/api/v1/bikes", Ct))!.Bikes;
        Assert.All(listed, b => Assert.Equal(0, b.ServiceDueCount));
    }

    [Fact]
    public async Task Reminders_ShouldNotBeVisibleOrChangeable_WhenTheyBelongToAnotherMember()
    {
        await using var api = await StartAsync();
        var (mine, _) = await NewMemberAsync(api);
        var (other, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(mine);
        var id = bike.Bike.Id;
        var reminderId = Assert.Single((await AddReminderAsync(mine, id, LubeChain())).Reminders).Id;
        var entry = await (await mine.PostAsJsonAsync($"/api/v1/bikes/{id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "New saddle" }, Ct)).Content.ReadFromJsonAsync<ServiceEntryResponse>(Ct);

        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/v1/bikes/{id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/v1/bikes/{id}/service", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/v1/bikes/{id}/service/jobs", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsJsonAsync($"/api/v1/bikes/{id}/reminders", LubeChain(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/v1/bikes/{id}/reminders/{reminderId}",
            new UpdateReminderRequest { Name = "x", IntervalMonths = 1 }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsJsonAsync($"/api/v1/bikes/{id}/reminders/{reminderId}/done", new MarkReminderDoneRequest(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.DeleteAsync($"/api/v1/bikes/{id}/reminders/{reminderId}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsJsonAsync($"/api/v1/bikes/{id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Mine now" }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/v1/bikes/{id}/service/{entry!.Id}",
            new UpdateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Mine now" }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.DeleteAsync($"/api/v1/bikes/{id}/service/{entry.Id}", Ct)).StatusCode);

        // Nothing changed for the owner.
        var detail = (await mine.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{id}", Ct))!;
        Assert.Equal("Lube the chain", Assert.Single(detail.Reminders).Name);
        Assert.Equal("New saddle", Assert.Single((await LogAsync(mine, id)).Entries).Title);
    }

    [Fact]
    public async Task ServiceLog_ShouldRefuseLinksToAnotherBikesPartOrReminder_WhenSaving()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var second = await AddBikeAsync(member);
        var part = Assert.Single((await (await member.PostAsJsonAsync($"/api/v1/bikes/{second.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1) }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components);
        var reminderId = Assert.Single((await AddReminderAsync(member, second.Bike.Id, LubeChain())).Reminders).Id;

        var onPart = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Chain", ComponentId = part.Id }, Ct);
        var onReminder = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Chain", ReminderId = reminderId }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, onPart.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, onReminder.StatusCode);
    }

    [Fact]
    public async Task ServiceLog_ShouldKeepTheEntryAndNotRewindTheReminder_WhenAnEntryFromDoneIsDeleted()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest { DoneOn = new DateOnly(2026, 10, 10) }, Ct);
        var entry = Assert.Single((await LogAsync(member, bike.Bike.Id)).Entries);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}/service/{entry.Id}", Ct)).StatusCode);

        Assert.Empty((await LogAsync(member, bike.Bike.Id)).Entries);
        var reminder = Assert.Single((await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{bike.Bike.Id}", Ct))!.Reminders);
        Assert.Equal(new DateOnly(2026, 10, 10), reminder.LastDoneOn);
    }

    [Fact]
    public async Task ServiceLog_ShouldKeepTheEntryWithoutTheLink_WhenItsReminderIsDeleted()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest(), Ct);

        await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}", Ct);

        var entry = Assert.Single((await LogAsync(member, bike.Bike.Id)).Entries);
        Assert.Null(entry.ReminderId);
        Assert.Equal("Lube the chain", entry.Title);
    }

    [Fact]
    public async Task ServiceLog_ShouldStoreTheCostAndEditEntries_WhenManagedByTheOwner()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, initialM: 1_000_000);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-02T08:00:00", 100);
        await AddRideAsync(api, userId, bike.Bike.Id, "2026-10-12T08:00:00", 50);

        var created = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service", new CreateServiceEntryRequest
        {
            Date = new DateOnly(2026, 10, 5),
            Title = "  Full service  ",
            Notes = "New cables",
            Place = "Bici Rossi",
            CostAmount = 85.50m,
            CostCurrency = "eur",
        }, Ct);
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var entry = (await created.Content.ReadFromJsonAsync<ServiceEntryResponse>(Ct))!;
        Assert.Equal("Full service", entry.Title);
        Assert.Equal(85.50m, entry.CostAmount);
        Assert.Equal("EUR", entry.CostCurrency);
        Assert.Equal(1_100_000, entry.BikeDistanceM);
        Assert.Equal(ServiceOrigins.Manual, entry.Origin);

        var edited = await member.PutAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service/{entry.Id}",
            new UpdateServiceEntryRequest { Date = new DateOnly(2026, 10, 20), Title = "Full service", Place = null }, Ct);
        var after = (await edited.Content.ReadFromJsonAsync<ServiceEntryResponse>(Ct))!;
        Assert.Null(after.Place);
        Assert.Null(after.CostAmount);
        Assert.Equal(1_150_000, after.BikeDistanceM);
    }

    [Theory]
    [InlineData(10.0, null)]
    [InlineData(null, "EUR")]
    [InlineData(-1.0, "EUR")]
    [InlineData(10.0, "EURO")]
    public async Task ServiceLog_ShouldRefuseTheEntry_WhenTheCostIsIncomplete(double? amount, string? currency)
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Service", CostAmount = (decimal?)amount, CostCurrency = currency }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ServiceEntries_ShouldRejectACurrencyWithoutAnAmount_WhenWrittenStraightToTheDatabase()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.ServiceEntries.Add(new ServiceEntry
        {
            Id = Guid.CreateVersion7(),
            BikeId = bike.Bike.Id,
            Date = new DateOnly(2026, 10, 5),
            Title = "Service",
            CostCurrency = "EUR",
            CreatedAt = Now,
        });

        var error = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync(Ct));
        Assert.Equal("23514", Assert.IsType<Npgsql.PostgresException>(error.InnerException).SqlState);
    }

    [Fact]
    public async Task ServiceLog_ShouldRefuseTheEntry_WhenTheDateIsInTheFutureOrTheTitleIsEmpty()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);

        var future = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service", new CreateServiceEntryRequest { Date = new DateOnly(2026, 11, 5), Title = "Service" }, Ct);
        var empty = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service", new CreateServiceEntryRequest { Date = new DateOnly(2026, 11, 4), Title = " " }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, future.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, empty.StatusCode);
    }

    [Fact]
    public async Task ServiceLog_ShouldListNewestFirstFilterByPartAndPage_WhenReading()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var part = Assert.Single((await (await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1) }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components);
        foreach (var (date, title, componentId) in new (string, string, Guid?)[]
                 { ("2026-10-01", "A", null), ("2026-10-03", "B", part.Id), ("2026-10-03", "C", null), ("2026-10-09", "D", part.Id) })
            (await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service",
                new CreateServiceEntryRequest { Date = DateOnly.Parse(date), Title = title, ComponentId = componentId }, Ct)).EnsureSuccessStatusCode();

        var all = await LogAsync(member, bike.Bike.Id);
        Assert.Equal(["D", "C", "B", "A"], all.Entries.Select(e => e.Title));
        Assert.False(all.HasMore);

        var first = await LogAsync(member, bike.Bike.Id, "?limit=2");
        Assert.Equal(["D", "C"], first.Entries.Select(e => e.Title));
        Assert.True(first.HasMore);
        var last = first.Entries[^1];
        var second = await LogAsync(member, bike.Bike.Id, $"?limit=2&beforeDate={last.Date:yyyy-MM-dd}&beforeId={last.Id}");
        Assert.Equal(["B", "A"], second.Entries.Select(e => e.Title));
        Assert.False(second.HasMore);

        Assert.Equal(["D", "B"], (await LogAsync(member, bike.Bike.Id, $"?componentId={part.Id}")).Entries.Select(e => e.Title));
    }

    [Fact]
    public async Task ServiceLog_ShouldWriteAnEntry_WhenAPartIsReplaced()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var old = Assert.Single((await (await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1), ExpectedDistanceM = 4_000_000 }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components);

        var replaced = await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components", new CreateComponentRequest
        {
            Type = "chain",
            Brand = "Shimano",
            Model = "CN-HG701",
            InstalledOn = new DateOnly(2026, 10, 20),
            ReplacesId = old.Id,
        }, Ct);

        Assert.Equal(HttpStatusCode.Created, replaced.StatusCode);
        var components = (await replaced.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components;
        Assert.Equal(new DateOnly(2026, 10, 20), components.Single(c => c.Id == old.Id).RemovedOn);
        var fresh = components.Single(c => c.Id != old.Id);
        var entry = Assert.Single((await LogAsync(member, bike.Bike.Id)).Entries);
        Assert.Equal("Replaced chain: Shimano CN-HG701", entry.Title);
        Assert.Equal(ServiceOrigins.Part, entry.Origin);
        Assert.Equal(new DateOnly(2026, 10, 20), entry.Date);
        Assert.Equal(fresh.Id, entry.ComponentId);
        Assert.Single((await LogAsync(member, bike.Bike.Id, $"?componentId={fresh.Id}")).Entries);
    }

    [Fact]
    public async Task ServiceLog_ShouldUseTheTitleTheAppSends_WhenAPartIsReplaced()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var old = Assert.Single((await (await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1) }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components);

        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components", new CreateComponentRequest
        {
            Type = "chain",
            InstalledOn = new DateOnly(2026, 10, 20),
            ReplacesId = old.Id,
            LogTitle = "Sostituito catena: Shimano CN-HG701",
        }, Ct);

        Assert.Equal("Sostituito catena: Shimano CN-HG701", Assert.Single((await LogAsync(member, bike.Bike.Id)).Entries).Title);
    }

    [Fact]
    public async Task ServiceLog_ShouldRefuseTheReplacement_WhenThePartIsNotFittedOrIsAnotherMembers()
    {
        await using var api = await StartAsync();
        var (mine, _) = await NewMemberAsync(api);
        var (other, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(mine);
        var theirs = await AddBikeAsync(other);
        var chain = Assert.Single((await (await other.PostAsJsonAsync($"/api/v1/bikes/{theirs.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1) }, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Components);

        var stolen = await mine.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 10, 20), ReplacesId = chain.Id }, Ct);

        Assert.Equal(HttpStatusCode.NotFound, stolen.StatusCode);
        Assert.Null(Assert.Single((await other.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{theirs.Bike.Id}", Ct))!.Components).RemovedOn);
        Assert.Empty((await LogAsync(mine, bike.Bike.Id)).Entries);
    }

    [Theory]
    [InlineData("road", "sealant_top_up", true)]
    [InlineData("track", "sealant_top_up", false)]
    public async Task ServiceJobs_ShouldFollowTheBikeKind_WhenListed(string kind, string job, bool offered)
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, kind);

        var jobs = (await member.GetFromJsonAsync<ListServiceJobsResponse>($"/api/v1/bikes/{bike.Bike.Id}/service/jobs", Ct))!.Jobs;

        Assert.Equal(offered, jobs.Any(j => j.Id == job));
        Assert.Equal(300_000, jobs.Single(j => j.Id == "chain_lube").IntervalDistanceM);
        Assert.Empty((await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{bike.Bike.Id}", Ct))!.Reminders); // asking adds nothing
    }

    [Fact]
    public async Task Bikes_ShouldRemoveRemindersAndLog_WhenTheBikeIsDeleted()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        var reminderId = Assert.Single((await AddReminderAsync(member, bike.Bike.Id, LubeChain())).Reminders).Id;
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/reminders/{reminderId}/done", new MarkReminderDoneRequest(), Ct);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}", Ct)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.MaintenanceReminders.AnyAsync(r => r.BikeId == bike.Bike.Id, Ct));
        Assert.False(await db.ServiceEntries.AnyAsync(e => e.BikeId == bike.Bike.Id, Ct));
    }

    [Fact]
    public async Task AccountExport_ShouldContainRemindersAndLog_WhenTheMemberHasThem()
    {
        await using var api = await StartAsync();
        var (member, userId) = await NewMemberAsync(api);
        var (other, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddReminderAsync(member, bike.Bike.Id, LubeChain());
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service",
            new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "New saddle", CostAmount = 40, CostCurrency = "EUR" }, Ct);
        var otherBike = await AddBikeAsync(other);
        await other.PostAsJsonAsync($"/api/v1/bikes/{otherBike.Bike.Id}/service", new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "Not mine" }, Ct);

        await using var scope = api.Services.CreateAsyncScope();
        var export = ActivatorUtilities.CreateInstance<AccountExport>(scope.ServiceProvider);
        using var stream = new MemoryStream();
        await export.WriteAsync(userId, stream, Ct);
        stream.Position = 0;
        using var zip = new System.IO.Compression.ZipArchive(stream);
        using var reader = new StreamReader(zip.GetEntry("bikes.json")!.Open());
        var bikes = JsonDocument.Parse(await reader.ReadToEndAsync(Ct)).RootElement;

        Assert.Equal("Lube the chain", bikes[0].GetProperty("maintenanceReminders")[0].GetProperty("name").GetString());
        var log = bikes[0].GetProperty("serviceLog");
        Assert.Equal(1, log.GetArrayLength());
        Assert.Equal("New saddle", log[0].GetProperty("title").GetString());
        Assert.Equal("EUR", log[0].GetProperty("costCurrency").GetString());
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveRemindersAndLog_WhenTheMemberDeletesTheAccount()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var (other, _) = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member);
        await AddReminderAsync(member, bike.Bike.Id, LubeChain());
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/service", new CreateServiceEntryRequest { Date = new DateOnly(2026, 10, 5), Title = "New saddle" }, Ct);
        var otherBike = await AddBikeAsync(other);
        await AddReminderAsync(other, otherBike.Bike.Id, LubeChain());

        var deleted = await member.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.MaintenanceReminders.AnyAsync(r => r.BikeId == bike.Bike.Id, Ct));
        Assert.False(await db.ServiceEntries.AnyAsync(e => e.BikeId == bike.Bike.Id, Ct));
        Assert.True(await db.MaintenanceReminders.AnyAsync(r => r.BikeId == otherBike.Bike.Id, Ct));
    }

    private static async Task UploadAndWaitAsync(HttpClient client, byte[] file)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", "ride.fit" } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            if ((await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct))!.Status != "processing") return;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }
}
