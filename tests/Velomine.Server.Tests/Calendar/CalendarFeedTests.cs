using System.Net;
using System.Net.Http.Json;
using Velomine.Server.Features.Clubs;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Calendar;

public sealed class CalendarFeedTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<string> NewAddressAsync(HttpClient client)
    {
        var response = await client.PostAsync("/api/v1/club/calendar-feed", null, Ct);
        response.EnsureSuccessStatusCode();
        var address = (await response.Content.ReadFromJsonAsync<CalendarFeedAddressResponse>(Ct))!;
        Assert.StartsWith("http://localhost:8080/api/v1/calendar/", address.Url);
        return address.Url;
    }

    private static Task<HttpResponseMessage> FetchAsync(TestApi api, string address) =>
        api.CreateClient().GetAsync(new Uri(address).PathAndQuery, Ct);

    [Fact]
    public async Task CalendarFeed_ShouldListTheClubsRides_WhenTheAddressIsSubscribedTo()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        var startsAt = DateTimeOffset.UtcNow.AddDays(3);
        var ride = await CalendarTestKit.PlanAsync(
            world.Coach.Client, CalendarTestKit.Request(routeId: route.Id, startsAt: startsAt, title: "Sunday ride"));
        (await world.Rider.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/participation", null, Ct)).EnsureSuccessStatusCode();

        var address = await NewAddressAsync(world.Rider.Client);
        var response = await FetchAsync(api, address);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/calendar", response.Content.Headers.ContentType!.MediaType);
        var calendar = await response.Content.ReadAsStringAsync(Ct);
        Assert.StartsWith("BEGIN:VCALENDAR\r\n", calendar);
        Assert.EndsWith("END:VCALENDAR\r\n", calendar);
        Assert.Contains("SUMMARY:Sunday ride", calendar);
        Assert.Contains("LOCATION:Fountain\\, Piazza Garibaldi", calendar);
        Assert.Contains("GEO:46;11", calendar);
        Assert.Contains($"URL:http://localhost:8080/club/rides/{ride.Ride.Id}", calendar);
        Assert.Contains("Route: Lake loop", calendar);
        // Three days out at eight in the morning: an instant in UTC, which every calendar shows locally.
        var expected = startsAt.UtcDateTime.ToString("yyyyMMddTHHmmss'Z'");
        Assert.Contains($"DTSTART:{expected}", calendar);
        // No member is named and the sign-up list is not in it.
        Assert.DoesNotContain("Rita Rider", calendar);
        Assert.DoesNotContain("Carlo Coach", calendar);
        Assert.DoesNotContain("ATTENDEE", calendar);
    }

    [Fact]
    public async Task CalendarFeed_ShouldMarkCancelledRides_WhenTheRideIsCalledOff()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ride = await CalendarTestKit.PlanAsync(world.Coach.Client);
        (await world.Coach.Client.PostAsync($"/api/v1/club/rides/{ride.Ride.Id}/cancel", null, Ct)).EnsureSuccessStatusCode();

        var calendar = await (await FetchAsync(api, await NewAddressAsync(world.Rider.Client))).Content.ReadAsStringAsync(Ct);

        Assert.Contains("STATUS:CANCELLED", calendar);
    }

    [Fact]
    public async Task CalendarFeed_ShouldStopTheOldAddress_WhenTheMemberReplacesItOrStopsIt()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var first = await NewAddressAsync(world.Rider.Client);
        var second = await NewAddressAsync(world.Rider.Client);

        Assert.Equal(HttpStatusCode.NotFound, (await FetchAsync(api, first)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await FetchAsync(api, second)).StatusCode);

        Assert.Equal(HttpStatusCode.NoContent, (await world.Rider.Client.DeleteAsync("/api/v1/club/calendar-feed", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await FetchAsync(api, second)).StatusCode);
        var status = await world.Rider.Client.GetFromJsonAsync<CalendarFeedStatusResponse>("/api/v1/club/calendar-feed", Ct);
        Assert.False(status!.Active);
    }

    [Fact]
    public async Task CalendarFeed_ShouldStopWorking_WhenTheMemberLeavesTheClub()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var address = await NewAddressAsync(world.Rider.Client);

        (await world.Rider.Client.PostAsync("/api/v1/club/leave", null, Ct)).EnsureSuccessStatusCode();

        // The address stops, and the member has no calendar to ask about any more.
        Assert.Equal(HttpStatusCode.NotFound, (await FetchAsync(api, address)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await world.Rider.Client.GetAsync("/api/v1/club/calendar-feed", Ct)).StatusCode);
    }

    [Fact]
    public async Task CalendarFeed_ShouldAnswerNotFound_WhenTheAddressIsUnknown()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var anonymous = api.CreateClient();

        Assert.Equal(HttpStatusCode.NotFound,
            (await anonymous.GetAsync("/api/v1/calendar/not-a-secret.ics", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await anonymous.GetAsync($"/api/v1/calendar/{Guid.NewGuid():N}.ics", Ct)).StatusCode);
    }

    [Fact]
    public async Task CalendarFeed_ShouldOnlyHaveTheClubRides_WhenTwoClubsHaveCalendars()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var ours = await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(title: "Our ride"));
        await CalendarTestKit.PlanAsync(world.OtherOwner.Client, CalendarTestKit.Request(title: "Their ride"));

        var ourCalendar = await (await FetchAsync(api, await NewAddressAsync(world.Rider.Client))).Content.ReadAsStringAsync(Ct);
        var theirCalendar = await (await FetchAsync(api, await NewAddressAsync(world.OtherRider.Client))).Content.ReadAsStringAsync(Ct);

        Assert.Contains("Our ride", ourCalendar);
        Assert.DoesNotContain("Their ride", ourCalendar);
        Assert.Contains("Their ride", theirCalendar);
        Assert.DoesNotContain("Our ride", theirCalendar);
        Assert.DoesNotContain(ours.Ride.Id.ToString("N"), theirCalendar);
    }

    [Fact]
    public async Task CalendarFeed_ShouldFoldLongLines_WhenTheTextIsLong()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(
            title: "A very long club ride title that goes on and on past the seventy-five octet limit of one line",
            notes: string.Join(' ', Enumerable.Repeat("Steady", 60))));

        var calendar = await (await FetchAsync(api, await NewAddressAsync(world.Rider.Client))).Content.ReadAsStringAsync(Ct);

        Assert.All(calendar.Split("\r\n"), line => Assert.True(System.Text.Encoding.UTF8.GetByteCount(line) <= 75, line));
        var unfolded = calendar.Replace("\r\n ", "");
        Assert.Contains("SUMMARY:A very long club ride title", unfolded);
        Assert.Contains("Steady Steady", unfolded);
    }
}
