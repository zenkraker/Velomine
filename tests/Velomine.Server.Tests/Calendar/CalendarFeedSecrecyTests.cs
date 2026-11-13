using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Clubs;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Calendar;

/// <summary>The calendar address is a secret: what the database keeps of it, and whose rides it can reach.</summary>
public sealed class CalendarFeedSecrecyTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task CalendarFeed_ShouldStoreOnlyTheHashOfTheAddress_WhenItIsCreated()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var created = await (await world.Rider.Client.PostAsync("/api/v1/club/calendar-feed", null, Ct))
            .Content.ReadFromJsonAsync<CalendarFeedAddressResponse>(Ct);
        var secret = new Uri(created!.Url).Segments[^1][..^4]; // "secret.ics"

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var feed = await db.CalendarFeeds.SingleAsync(f => f.UserId == world.Rider.Id, Ct);

        Assert.Equal(32, feed.TokenHash.Length);
        Assert.Equal(CalendarFeedTokens.Hash(secret), feed.TokenHash);

        // Nothing anywhere in the row spells the address out.
        var everyColumn = $"{feed.UserId}|{feed.ClubId}|{feed.CreatedAt}|{Convert.ToHexString(feed.TokenHash)}";
        Assert.DoesNotContain(secret, everyColumn, StringComparison.Ordinal);
    }

    [Fact]
    public async Task CalendarFeed_ShouldShowTheAddressOnlyOnce_WhenItIsAskedForAgain()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var created = await (await world.Rider.Client.PostAsync("/api/v1/club/calendar-feed", null, Ct))
            .Content.ReadFromJsonAsync<CalendarFeedAddressResponse>(Ct);

        var status = await world.Rider.Client.GetFromJsonAsync<CalendarFeedStatusResponse>("/api/v1/club/calendar-feed", Ct);
        var again = await (await world.Rider.Client.PostAsync("/api/v1/club/calendar-feed", null, Ct))
            .Content.ReadFromJsonAsync<CalendarFeedAddressResponse>(Ct);

        Assert.True(status!.Active);
        Assert.NotEqual(created!.Url, again!.Url); // replacing it ends the old one
        Assert.Equal(System.Net.HttpStatusCode.NotFound,
            (await api.CreateClient().GetAsync(new Uri(created.Url).PathAndQuery, Ct)).StatusCode);
    }

    [Fact]
    public async Task CalendarFeed_ShouldCarryNoRideOfAnotherClub_WhenTwoClubsPlanRides()
    {
        await using var api = await CalendarTestKit.StartAsync(postgres);
        var world = await NewWorldAsync(api);
        await CalendarTestKit.PlanAsync(world.Coach.Client, CalendarTestKit.Request(title: "Our club ride"));
        var theirOwner = await NewMemberAsync(api, "Otto Other");
        var theirClub = await CreateClubAsync(api, theirOwner);
        var theirCoach = await NewClubMemberAsync(api, theirClub, "Carlo Other");
        var theirRoute = await CreateRouteAsync(theirCoach.Client, LineRequest("Their loop", "road", 10));
        await CalendarTestKit.PlanAsync(theirCoach.Client, CalendarTestKit.Request(routeId: theirRoute.Id, title: "Their club ride"));

        var address = await (await world.Rider.Client.PostAsync("/api/v1/club/calendar-feed", null, Ct))
            .Content.ReadFromJsonAsync<CalendarFeedAddressResponse>(Ct);
        var calendar = await api.CreateClient().GetStringAsync(new Uri(address!.Url).PathAndQuery, Ct);

        Assert.Contains("SUMMARY:Our club ride", calendar);
        Assert.DoesNotContain("Their club ride", calendar);
        Assert.DoesNotContain("Their loop", calendar);
    }
}
