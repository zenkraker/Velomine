using System.Net;
using System.Net.Http.Json;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Calendar;

public sealed class CalendarTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<NotificationResponse[]> NotificationsAsync(HttpClient client, string type)
    {
        var list = await client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct);
        return [.. list!.Notifications.Where(n => n.Type == type)];
    }

    [Fact]
    public async Task PlanClubRide_ShouldTellEveryMember_WhenACoachPlansTheSundayRide()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        var startsAt = DateTimeOffset.FromUnixTimeSeconds(DateTimeOffset.UtcNow.AddDays(3).ToUnixTimeSeconds());

        var ride = await CalendarTestKit.PlanAsync(
            world.Coach.Client, CalendarTestKit.Request(routeId: route.Id, startsAt: startsAt));

        Assert.Equal("Sunday ride", ride.Ride.Title);
        Assert.Equal(startsAt, ride.Ride.StartsAt);
        Assert.Equal(60, ride.Ride.UtcOffsetMinutes);
        Assert.Equal(route.Id, ride.Ride.RouteId);
        Assert.Equal(route.Name, ride.Ride.RouteName);
        Assert.Equal("Carlo Coach", ride.Ride.CreatedByName);
        Assert.True(ride.CanPlan);
        // About a kilometre at a steady pace is under half an hour, which is the shortest a calendar block gets.
        Assert.Equal(startsAt.AddMinutes(30), ride.Ride.EndsAt);

        foreach (var member in new[] { world.Owner, world.Rider })
        {
            var told = await NotificationsAsync(member.Client, NotificationTypes.ClubRidePlanned);
            Assert.Equal([ride.Ride.Id], told.Select(n => n.PlannedRideId));
            Assert.Equal("Sunday ride", Assert.Single(told).Subject);
        }

        // The coach planned it; they are not told about their own action.
        Assert.Empty(await NotificationsAsync(world.Coach.Client, NotificationTypes.ClubRidePlanned));
    }

    [Fact]
    public async Task PlanClubRide_ShouldRefuse_WhenTheCallerIsARiderOrTheRouteIsNotInTheLibrary()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var otherRoute = await CreateRouteAsync(world.OtherRider.Client);

        Assert.Equal(HttpStatusCode.Forbidden,
            (await world.Rider.Client.PostAsJsonAsync("/api/v1/club/rides", CalendarTestKit.Request(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await world.Coach.Client.PostAsJsonAsync(
                "/api/v1/club/rides", CalendarTestKit.Request(routeId: Guid.NewGuid()), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await world.Coach.Client.PostAsJsonAsync(
                "/api/v1/club/rides", CalendarTestKit.Request(routeId: otherRoute.Id), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await world.Coach.Client.PostAsJsonAsync(
                "/api/v1/club/rides", CalendarTestKit.Request(startsAt: DateTimeOffset.UtcNow.AddHours(-1)), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await world.Coach.Client.PostAsJsonAsync(
                "/api/v1/club/rides", CalendarTestKit.Request(pace: "race"), Ct)).StatusCode);
    }

    [Fact]
    public async Task ClubRides_ShouldNotBeVisible_WhenRequestComesFromAnotherClubOrNoClub()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);
        var id = ride.Ride.Id;

        foreach (var outsider in new[] { world.OtherOwner, world.OtherRider })
        {
            var client = outsider.Client;
            // Another club's calendar is its own: it exists and is empty, never ours.
            var list = await CalendarTestKit.RidesAsync(client);
            Assert.Empty(list!.Upcoming);
            Assert.Empty(list.Past);
            Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/v1/club/rides/{id}", Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound,
                (await client.PutAsJsonAsync($"/api/v1/club/rides/{id}", CalendarTestKit.Request(), Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.PostAsync($"/api/v1/club/rides/{id}/cancel", null, Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.PostAsync($"/api/v1/club/rides/{id}/participation", null, Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.DeleteAsync($"/api/v1/club/rides/{id}/participation", Ct)).StatusCode);
            // Their own private address is theirs; it lists nothing of this club.
            Assert.False((await client.GetFromJsonAsync<CalendarFeedStatusResponse>("/api/v1/club/calendar-feed", Ct))!.Active);
        }

        // A rider with no club has no calendar at all.
        var loner = world.Loner.Client;
        Assert.Equal(HttpStatusCode.NotFound, (await loner.GetAsync("/api/v1/club/rides", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await loner.PostAsJsonAsync("/api/v1/club/rides", CalendarTestKit.Request(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.GetAsync($"/api/v1/club/rides/{id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.PostAsync($"/api/v1/club/rides/{id}/cancel", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.PostAsync($"/api/v1/club/rides/{id}/participation", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.DeleteAsync($"/api/v1/club/rides/{id}/participation", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.GetAsync("/api/v1/club/calendar-feed", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.PostAsync("/api/v1/club/calendar-feed", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await loner.DeleteAsync("/api/v1/club/calendar-feed", Ct)).StatusCode);

        Assert.Single((await CalendarTestKit.RidesAsync(world.Rider.Client))!.Upcoming);
    }

    [Fact]
    public async Task JoinClubRide_ShouldShowTheRiderToTheClub_WhenTheySayTheyAreIn()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);

        var joined = await (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct))
            .Content.ReadFromJsonAsync<ClubRideDetailResponse>(Ct);

        Assert.True(joined!.Ride.IsSignedUp);
        Assert.Equal(1, joined.Ride.SignUpCount);
        Assert.Equal([world.Rider.Id], joined.Participants.Select(p => p.UserId));
        Assert.Equal("Rita Rider", Assert.Single(joined.Participants).DisplayName);

        // Another member sees who is in; joining twice changes nothing.
        await world.Coach.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct);
        await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct);
        var seen = await CalendarTestKit.RideAsync(world.Owner.Client, ride.Ride.Id);
        Assert.Equal(2, seen!.Participants.Length);

        Assert.Equal(HttpStatusCode.NoContent,
            (await world.Rider.Client.DeleteAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", Ct)).StatusCode);
        var after = await CalendarTestKit.RideAsync(world.Owner.Client, ride.Ride.Id);
        Assert.Equal([world.Coach.Id], after!.Participants.Select(p => p.UserId));
    }

    [Fact]
    public async Task JoinClubRide_ShouldRefuseWithTheReason_WhenTheRideIsFullCancelledOrStarted()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var full = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(maxRiders: 1));
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{full.Ride.Id}/participation", null, Ct))
            .EnsureSuccessStatusCode();

        var refused = await world.Owner.Client.PostAsync($"/api/v1/club/rides/{full.Ride.Id}/participation", null, Ct);
        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);
        Assert.Contains("full", await refused.Content.ReadAsStringAsync(Ct), StringComparison.OrdinalIgnoreCase);

        var cancelled = await CalendarTestKit.PlanAsync(world.Coach.Client);
        (await world.Coach.Client.PostAsync($"/api/v1/club/rides/{cancelled.Ride.Id}/cancel", null, Ct)).EnsureSuccessStatusCode();
        var notRunning = await world.Rider.Client.PostAsync($"/api/v1/club/rides/{cancelled.Ride.Id}/participation", null, Ct);
        Assert.Equal(HttpStatusCode.Conflict, notRunning.StatusCode);
        Assert.Contains("cancelled", await notRunning.Content.ReadAsStringAsync(Ct), StringComparison.OrdinalIgnoreCase);

        var started = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(title: "Long gone"));
        var edit = CalendarTestKit.Edit(
            started.Ride.Id, CalendarTestKit.Request(title: "Long gone", startsAt: DateTimeOffset.UtcNow.AddHours(-2)));
        (await world.Coach.Client.PutAsJsonAsync($"/api/v1/club/rides/{started.Ride.Id}", edit, Ct)).EnsureSuccessStatusCode();
        var tooLate = await world.Rider.Client.PostAsync($"/api/v1/club/rides/{started.Ride.Id}/participation", null, Ct);
        Assert.Equal(HttpStatusCode.Conflict, tooLate.StatusCode);
        Assert.Contains("started", await tooLate.Content.ReadAsStringAsync(Ct), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task JoinClubRide_ShouldGiveTheLastPlaceToOneRider_WhenTwoClickAtOnce()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(maxRiders: 1));

        var answers = await Task.WhenAll(
            world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct),
            world.Owner.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct));

        Assert.Equal([HttpStatusCode.OK, HttpStatusCode.Conflict], answers.Select(r => r.StatusCode).Order().ToArray());
        Assert.Equal(1, (await CalendarTestKit.RideAsync(world.Coach.Client, ride.Ride.Id))!.Ride.SignUpCount);
    }

    [Fact]
    public async Task JoinClubRide_ShouldCountOnePlace_WhenTheSameRiderClicksTwice()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);

        var answers = await Task.WhenAll(
            world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct),
            world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct));

        Assert.All(answers, r => Assert.Equal(HttpStatusCode.OK, r.StatusCode));
        Assert.Equal(1, (await CalendarTestKit.RideAsync(world.Coach.Client, ride.Ride.Id))!.Ride.SignUpCount);
    }

    [Fact]
    public async Task AccountExport_ShouldIncludeClubRides_WhenTheMemberIsIn()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(title: "Sunday ride"));
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct)).EnsureSuccessStatusCode();

        var link = (await (await world.Rider.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct))
            .Content.ReadFromJsonAsync<Velomine.Server.Features.Accounts.ExportLinkResponse>(Ct))!;
        var zip = new System.IO.Compression.ZipArchive(
            await (await api.CreateClient().GetAsync(link.Path, Ct)).Content.ReadAsStreamAsync(Ct));

        using var reader = new StreamReader(zip.GetEntry("club-rides.json")!.Open());
        var json = await reader.ReadToEndAsync(Ct);
        Assert.Contains("Sunday ride", json);
    }

    [Fact]
    public async Task UpdateClubRide_ShouldTellOnlyTheRidersWhoAreIn_WhenTheTimeOrMeetingPointChanges()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct)).EnsureSuccessStatusCode();

        var moved = CalendarTestKit.Edit(
            ride.Ride.Id, CalendarTestKit.Request(startsAt: ride.Ride.StartsAt.AddHours(1)));
        (await world.Coach.Client.PutAsJsonAsync($"/api/v1/club/rides/{ride.Ride.Id}", moved, Ct)).EnsureSuccessStatusCode();

        Assert.Single(await NotificationsAsync(world.Rider.Client, NotificationTypes.ClubRideChanged));
        // The owner is a member but not in, so the change is none of their business.
        Assert.Empty(await NotificationsAsync(world.Owner.Client, NotificationTypes.ClubRideChanged));

        // A change to the notes alone tells nobody.
        moved.Notes = "Bring a light";
        (await world.Coach.Client.PutAsJsonAsync($"/api/v1/club/rides/{ride.Ride.Id}", moved, Ct)).EnsureSuccessStatusCode();
        Assert.Single(await NotificationsAsync(world.Rider.Client, NotificationTypes.ClubRideChanged));
    }

    [Fact]
    public async Task CancelClubRide_ShouldMarkItAndTellTheRidersWhoAreIn_WhenACoachCancels()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct)).EnsureSuccessStatusCode();

        var cancelled = await (await world.Coach.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/cancel", null, Ct))
            .Content.ReadFromJsonAsync<ClubRideDetailResponse>(Ct);

        Assert.True(cancelled!.Ride.IsCancelled);
        Assert.Single(await NotificationsAsync(world.Rider.Client, NotificationTypes.ClubRideCancelled));
        Assert.Empty(await NotificationsAsync(world.Owner.Client, NotificationTypes.ClubRideCancelled));

        // Cancelling again says nothing a second time.
        (await world.Coach.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/cancel", null, Ct)).EnsureSuccessStatusCode();
        Assert.Single(await NotificationsAsync(world.Rider.Client, NotificationTypes.ClubRideCancelled));
        // The ride stays on the calendar, marked cancelled.
        Assert.True(Assert.Single((await CalendarTestKit.RidesAsync(world.Rider.Client))!.Upcoming).IsCancelled);
    }

    [Fact]
    public async Task UpdateClubRide_ShouldRefuse_WhenTheCallerIsARider()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);
        var edit = CalendarTestKit.Edit(ride.Ride.Id, CalendarTestKit.Request(title: "Mine now"));

        Assert.Equal(HttpStatusCode.Forbidden,
            (await world.Rider.Client.PutAsJsonAsync($"/api/v1/club/rides/{ride.Ride.Id}", edit, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden,
            (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/cancel", null, Ct)).StatusCode);
        // A route that is no longer in the library cannot be attached.
        Assert.Equal(HttpStatusCode.BadRequest,
            (await world.Coach.Client.PutAsJsonAsync(
                $"/api/v1/club/rides/{ride.Ride.Id}", CalendarTestKit.Request(routeId: Guid.NewGuid()), Ct)).StatusCode);
    }

    [Fact]
    public async Task PlannedRide_ShouldKeepGoing_WhenItsRouteAndPlannerGoAway()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(routeId: route.Id));
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct)).EnsureSuccessStatusCode();

        // The route's owner withdraws it: the ride stays and has no route, and nobody is told.
        (await world.Rider.Client.DeleteAsync($"/api/v1/routes/{route.Id}/share", Ct)).EnsureSuccessStatusCode();
        var withoutRoute = await CalendarTestKit.RideAsync(world.Owner.Client, ride.Ride.Id);
        Assert.Null(withoutRoute!.Ride.RouteId);
        Assert.Null(withoutRoute.Ride.RouteName);
        Assert.True(withoutRoute.Ride.EndsAt == withoutRoute.Ride.StartsAt.AddHours(2));
        Assert.Empty(await NotificationsAsync(world.Rider.Client, NotificationTypes.ClubRideChanged));

        // Deleting it for good leaves the ride standing too.
        (await world.Rider.Client.DeleteAsync($"/api/v1/routes/{route.Id}", Ct)).EnsureSuccessStatusCode();
        Assert.NotNull(await CalendarTestKit.RideAsync(world.Owner.Client, ride.Ride.Id));

        // The planner's account going away does not take the club's ride with it.
        (await world.Coach.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new Velomine.Server.Features.Accounts.DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct))
            .EnsureSuccessStatusCode();
        var stillThere = await CalendarTestKit.RideAsync(world.Owner.Client, ride.Ride.Id);
        Assert.NotNull(stillThere);
        Assert.Null(stillThere!.Ride.CreatedByName);
    }
}
