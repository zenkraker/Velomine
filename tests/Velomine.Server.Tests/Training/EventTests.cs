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
using Velomine.Server.Features.Training;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The races and tours a rider is training for: one table, owner only, and a ride that was the rider's only one that
/// day fills an event's ride by itself.
/// </summary>
public sealed class EventTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static readonly DateTimeOffset Now = DateTimeOffset.UtcNow;

    /// <summary>Midday UTC, so its local date is the same in every zone a member may have.</summary>
    private static readonly DateTimeOffset From = new(Start.AddHours(12), TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    /// <summary>
    /// Waits until the reader has saved the rides it has read. A ride is marked ready before the rest of that read is
    /// written, so a test that asks for a suggestion or an event reads the database too early without this.
    /// </summary>
    /// <summary>
    /// Waits until the reader has saved what the last upload read. A ride is marked ready before the rest of that read
    /// is written, so a test that asks for the event's link reads the database too early without this.
    /// </summary>
    private static async Task WaitForTheLinkAsync(HttpClient client, Guid eventId)
    {
        for (var i = 0; i < 500; i++)
        {
            if ((await ListAsync(client)).Events.Any(e => e.Id == eventId && e.RideId != null)) return;
            await Task.Delay(20);
        }

        throw new TimeoutException("The ride read did not link the event within 10 seconds.");
    }

    /// <summary>A member whose zone is UTC, so the fixed instant's date is the local date.</summary>
    private static async Task<TestMember> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var member = await api.NewMemberAsync(name);
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest(name, null, null, null, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        return member;
    }

    private static Task<HttpResponseMessage> AddAsync(HttpClient client, string name, DateOnly date, string kind = "race") =>
        client.PostAsJsonAsync("/api/v1/training/events", new { Name = name, Date = date.ToString("yyyy-MM-dd"), Kind = kind }, Ct);

    private static Task<HttpResponseMessage> UpdateAsync(HttpClient client, Guid id, string name, DateOnly date) =>
        client.PutAsJsonAsync($"/api/v1/training/events/{id}",
            new { Name = name, Date = date.ToString("yyyy-MM-dd"), Kind = "race" }, Ct);

    private static async Task<ListEventsResponse> ListAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListEventsResponse>("/api/v1/training/events", Ct))!;

    [Fact]
    public async Task AddEvent_ShouldBeListed_WhenValid()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var created = await AddAsync(member.Client, "Gran Fondo Pinzolo", new DateOnly(2026, 5, 10), "sportive");

        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var added = await created.Content.ReadFromJsonAsync<EventResponse>(Ct);
        Assert.Equal("Gran Fondo Pinzolo", added!.Name);
        Assert.Equal("sportive", added.Kind);
        Assert.Equal(new DateOnly(2026, 5, 10), added.Date);
        Assert.Null(added.RideId);
        var listed = Assert.Single((await ListAsync(member.Client)).Events);
        Assert.Equal(added.Id, listed.Id);
    }

    [Fact]
    public async Task AddEvent_ShouldRefuse_WhenTheNameIsEmpty()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.BadRequest, (await AddAsync(member.Client, "", new DateOnly(2026, 5, 10))).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await AddAsync(member.Client, "   ", new DateOnly(2026, 5, 10))).StatusCode);
        Assert.Empty((await ListAsync(member.Client)).Events);
    }

    [Fact]
    public async Task ListEvents_ShouldPutTheNextOnesFirst_WhenThereArePastOnesToo()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var today = DateOnly.FromDateTime(Now.UtcDateTime);
        await AddAsync(member.Client, "Last year", today.AddDays(-300));
        await AddAsync(member.Client, "Later", today.AddDays(60));
        await AddAsync(member.Client, "Next week", today.AddDays(7));
        await AddAsync(member.Client, "Last week", today.AddDays(-7));

        var events = (await ListAsync(member.Client)).Events;

        Assert.Equal(["Next week", "Later", "Last week", "Last year"], events.Select(e => e.Name));
    }

    [Fact]
    public async Task UpdateEvent_ShouldChangeTheFields_WhenItIsTheRiderSOwn()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var created = await (await AddAsync(member.Client, "Race", new DateOnly(2026, 5, 10))).Content.ReadFromJsonAsync<EventResponse>(Ct);

        var updated = await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}",
            new { Name = "Tour of the Lakes", Date = "2026-06-01", Kind = "tour", DistanceM = 120_000.0, Notes = "Two days" }, Ct);

        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);
        var eventResponse = await updated.Content.ReadFromJsonAsync<EventResponse>(Ct);
        Assert.Equal("Tour of the Lakes", eventResponse!.Name);
        Assert.Equal("tour", eventResponse.Kind);
        Assert.Equal(new DateOnly(2026, 6, 1), eventResponse.Date);
        Assert.Equal(120_000, eventResponse.DistanceM);
        Assert.Equal("Two days", eventResponse.Notes);
    }

    [Fact]
    public async Task DeleteEvent_ShouldRemoveIt_WhenItIsTheRiderSOwn()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var created = await (await AddAsync(member.Client, "Race", new DateOnly(2026, 5, 10))).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.DeleteAsync($"/api/v1/training/events/{created!.Id}", Ct)).StatusCode);

        Assert.Empty((await ListAsync(member.Client)).Events);
    }

    [Fact]
    public async Task Events_ShouldNotBeVisible_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        var created = await (await AddAsync(owner.Client, "Race", new DateOnly(2026, 5, 10))).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Empty((await ListAsync(other.Client)).Events);
        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}",
            new { Name = "Mine now", Date = "2026-05-10", Kind = "race" }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await other.Client.DeleteAsync($"/api/v1/training/events/{created.Id}", Ct)).StatusCode);
        // The owner's event is untouched.
        Assert.Equal("Race", Assert.Single((await ListAsync(owner.Client)).Events).Name);
    }

    [Fact]
    public async Task Event_ShouldLinkTheRide_WhenItIsTheOnlyRideThatDay()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        // The ride's own header says ready before its read is finished: the whole read is waited for here, or the
        // event would be looked at before the link it writes.
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        for (var i = 0; i < 500; i++)
        {
            await using var scope = api.Services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            if (await db.Events.AnyAsync(e => e.Id == created!.Id && e.RideId != null, Ct)) break;
            await Task.Delay(20, Ct);
        }

        Assert.Equal(ride.Id, Assert.Single((await ListAsync(member.Client)).Events, e => e.Id == created!.Id).RideId);
    }

    [Fact]
    public async Task Event_ShouldNotLink_WhenThereAreTwoRides()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        // Two rides of the day in one file: two devices' copies of one ride would be a duplicate instead, seen only when
        // they start within two minutes of each other with the same elapsed time and distance.
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600),
            new FitSession(From.AddHours(1).UtcDateTime, 1200)));

        Assert.Null(Assert.Single((await ListAsync(member.Client)).Events, e => e.Id == created!.Id).RideId);
    }

    [Fact]
    public async Task Event_ShouldNotLink_WhenTwoEventsShareTheDate()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var first = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var second = await (await AddAsync(member.Client, "The club ride", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        // Two events of the day cannot both have the one ride: neither takes it, and the rider picks.
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        var events = (await ListAsync(member.Client)).Events;
        Assert.Null(Assert.Single(events, e => e.Id == first!.Id).RideId);
        Assert.Null(Assert.Single(events, e => e.Id == second!.Id).RideId);
    }

    [Fact]
    public async Task Event_ShouldLinkTheRide_WhenAnEventIsAddedOnTheDayOfOneRide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Equal(ride.Id, created!.RideId);
        Assert.Equal(ride.Id, Assert.Single((await ListAsync(member.Client)).Events).RideId);
    }

    [Fact]
    public async Task Event_ShouldLinkTheRide_WhenTheDateIsChangedToTheDayOfOneRide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        var created = await (await AddAsync(member.Client, "Local race", day.AddDays(1))).Content.ReadFromJsonAsync<EventResponse>(Ct);
        Assert.Null(created!.RideId);

        var changed = await (await UpdateAsync(member.Client, created.Id, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Equal(ride.Id, changed!.RideId);
    }

    [Fact]
    public async Task Event_ShouldNotLink_WhenTheNewEventIsNotTheOnlyUnlinkedOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        // Two events of the day are already waiting for a ride, so a third one is not the day's only choice.
        await AddAsync(member.Client, "Local race", day);
        await AddAsync(member.Client, "The club ride", day);
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        var created = await (await AddAsync(member.Client, "Another race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Null(created!.RideId);
    }

    [Fact]
    public async Task UpdateEvent_ShouldDropTheLink_WhenTheDateMovesAwayFromTheRide()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        Assert.Equal(ride.Id, created!.RideId);

        var changed = await (await UpdateAsync(member.Client, created.Id, created.Name, day.AddDays(1))).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Null(changed!.RideId);
    }

    [Fact]
    public async Task UpdateEvent_ShouldNotRelink_WhenOnlyTheNameChanges()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}/ride", new { RideId = (Guid?)null }, Ct);

        var changed = await (await UpdateAsync(member.Client, created.Id, "Another name", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Null(changed!.RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldRefuse_WhenTheRideIsOnAnotherDate()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var other = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.AddDays(1).UtcDateTime, 600)));

        var set = await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}/ride", new { RideId = other.Id }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, set.StatusCode);
        Assert.Null(Assert.Single((await ListAsync(member.Client)).Events).RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldAccept_WhenTheRideIsOnTheEventDayButAnotherUtcDay()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        // The file says UTC+2, so a ride starting at 22:00 UTC was ridden on the next day where the rider was.
        var start = new DateTime(2026, 10, 3, 22, 0, 0, DateTimeKind.Utc);
        var day = new DateOnly(2026, 10, 4);
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(start, 600)));
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        var set = await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}/ride", new { RideId = ride.Id }, Ct);

        Assert.Equal(HttpStatusCode.OK, set.StatusCode);
        Assert.Equal(ride.Id, (await set.Content.ReadFromJsonAsync<EventResponse>(Ct))!.RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldPickOneOfTheDaySRides_WhenTheRiderChooses()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var first = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        var second = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.AddHours(1).UtcDateTime, 1200)));

        var set = await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}/ride", new { RideId = second.Id }, Ct);

        Assert.Equal(HttpStatusCode.OK, set.StatusCode);
        Assert.NotEqual(first.Id, second.Id);
        Assert.Equal(second.Id, (await set.Content.ReadFromJsonAsync<EventResponse>(Ct))!.RideId);
        Assert.Equal(second.Id, Assert.Single((await ListAsync(member.Client)).Events).RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldUnlink_WhenTheRideIsNull()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var created = await (await AddAsync(member.Client, "Local race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        var set = await member.Client.PutAsJsonAsync($"/api/v1/training/events/{created!.Id}/ride", new { RideId = (Guid?)null }, Ct);

        Assert.Equal(HttpStatusCode.OK, set.StatusCode);
        Assert.Null((await set.Content.ReadFromJsonAsync<EventResponse>(Ct))!.RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldReturn404_WhenTheRideBelongsToAnotherRider()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        var created = await (await AddAsync(other.Client, "Race", new DateOnly(2026, 5, 10))).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var theirs = await TestApi.UploadAndWaitAsync(owner.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.PutAsJsonAsync(
            $"/api/v1/training/events/{created!.Id}/ride", new { RideId = theirs.Id }, Ct)).StatusCode);
        Assert.Null(Assert.Single((await ListAsync(other.Client)).Events).RideId);
    }

    [Fact]
    public async Task SetEventRide_ShouldReturn404_WhenTheEventBelongsToAnotherRider()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var theirs = await (await AddAsync(owner.Client, "Race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var mine = await TestApi.UploadAndWaitAsync(other.Client, Fit(new FitSession(From.UtcDateTime, 600)));

        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.PutAsJsonAsync(
            $"/api/v1/training/events/{theirs!.Id}/ride", new { RideId = mine.Id }, Ct)).StatusCode);
        Assert.Null(Assert.Single((await ListAsync(owner.Client)).Events).RideId);
    }

    [Fact]
    public async Task Event_ShouldLinkItsOwnRide_WhenAnotherMemberHasARideAndAnEventThatDate()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        var day = DateOnly.FromDateTime(From.UtcDateTime);
        var theirs = await (await AddAsync(other.Client, "Their race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);
        var theirRide = await TestApi.UploadAndWaitAsync(other.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        await WaitForTheLinkAsync(other.Client, theirs!.Id);

        var mine = await TestApi.UploadAndWaitAsync(me.Client, Fit(new FitSession(From.UtcDateTime, 600)));
        var created = await (await AddAsync(me.Client, "My race", day)).Content.ReadFromJsonAsync<EventResponse>(Ct);

        // Neither the other member's ride nor their event of that date is counted for mine.
        Assert.Equal(mine.Id, created!.RideId);
        Assert.Equal(theirRide.Id, Assert.Single((await ListAsync(other.Client)).Events).RideId);
    }

    [Fact]
    public async Task Event_ShouldLinkTheRide_WhenTheRideIsOnTheEventDayAtALargeOffset()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        // At UTC+14, 16:00 UTC on the 3rd was 06:00 on the 4th where the rider was: a day before in UTC, the same day
        // locally as the event.
        var ride = await TestApi.UploadAndWaitAsync(member.Client,
            Fit(new FitSession(new DateTime(2026, 10, 3, 16, 0, 0, DateTimeKind.Utc), 600, UtcOffsetHours: 14)));

        var created = await (await AddAsync(member.Client, "Local race", new DateOnly(2026, 10, 4)))
            .Content.ReadFromJsonAsync<EventResponse>(Ct);

        Assert.Equal(ride.Id, created!.RideId);
    }

    [Fact]
    public async Task AccountExport_ShouldContainEvents_WhenTheMemberHasThem()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        await AddAsync(me.Client, "Gran Fondo Pinzolo", new DateOnly(2026, 5, 10), "sportive");
        await AddAsync(other.Client, "Not mine", new DateOnly(2026, 5, 10));

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        var entry = zip.GetEntry("events.json");
        Assert.NotNull(entry);
        using var stream = entry.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var row = Assert.Single(document.RootElement.EnumerateArray());
        Assert.Equal("Gran Fondo Pinzolo", row.GetProperty("name").GetString());
        Assert.Equal("sportive", row.GetProperty("kind").GetString());
        Assert.Equal("2026-05-10", row.GetProperty("date").GetString());
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveEvents_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var me = await NewMemberAsync(api);
        await AddAsync(me.Client, "Gran Fondo Pinzolo", new DateOnly(2026, 5, 10));

        var deleted = await me.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.Events.AnyAsync(e => e.UserId == me.Id, Ct));
    }
}
