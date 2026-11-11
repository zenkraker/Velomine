using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Routes;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Routes;

[Collection("postgres")]
public sealed class RoutesTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task CreateRoute_ShouldLeaveOutThePrivacyZone_WhenTheRouteComesFromARide()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);
        // The ride starts at 46.0, 11.0 and goes north: the first 500 m are inside the zone.
        await AddZoneAsync(world.Rider.Client, 46.0, 11.0, 500);

        var draft = await world.Rider.Client.GetFromJsonAsync<RouteDraftResponse>($"/api/v1/rides/{rideId}/route-draft", Ct);
        var response = await world.Rider.Client.PostAsJsonAsync(
            "/api/v1/routes", new CreateRouteRequest { RideId = rideId, Name = "Morning", Surface = "road" }, Ct);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var route = (await response.Content.ReadFromJsonAsync<RouteDetailResponse>(Ct))!;
        foreach (var (latitude, longitude) in route.Latitude.Zip(route.Longitude))
            Assert.True(Geo.Metres(46.0, 11.0, latitude, longitude) > 500, "A point inside the privacy zone was copied.");
        Assert.Equal(draft!.Latitude[0], route.Latitude[0]);
        Assert.Equal(draft.DistanceM, route.DistanceM, 3);
        // The ride is 4.8 km; 500 m are hidden.
        Assert.InRange(route.DistanceM, 4_200, 4_400);
        Assert.NotNull(route.ClimbingM);
        Assert.Equal(world.Rider.Id, route.OwnerId);
        Assert.True(route.IsMine);
        Assert.True(route.IsShared);
    }

    [Fact]
    public async Task CreateRoute_ShouldTrimTheStartAndEnd_WhenThePrivacySettingsTrimThem()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);
        (await world.Rider.Client.PutAsJsonAsync(
            "/api/v1/privacy/settings",
            new Velomine.Server.Features.Privacy.UpdatePrivacyRequest
            {
                HideHeartRate = false,
                HidePower = false,
                HideCadence = false,
                HideSpeed = false,
                HideElevation = true,
                HideTemperature = false,
                TrimStartM = 1000,
                TrimEndM = 1000,
            },
            Ct)).EnsureSuccessStatusCode();

        var route = await CreateRouteAsync(
            world.Rider.Client, new CreateRouteRequest { RideId = rideId, Name = "Trimmed", Surface = "road" });

        Assert.InRange(route.DistanceM, 2_700, 2_900);
        Assert.Null(route.Elevation);
        Assert.Null(route.ClimbingM);
    }

    [Fact]
    public async Task CreateRoute_ShouldKeepTheWholeLine_WhenThereIsNoPrivacyRule()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);

        var route = await CreateRouteAsync(
            world.Rider.Client,
            new CreateRouteRequest { RideId = rideId, Name = "All of it", Surface = "gravel", Description = "  Steady  " });

        Assert.InRange(route.DistanceM, 4_700, 4_900);
        Assert.NotNull(route.Elevation);
        Assert.Equal("Steady", route.Description);
        Assert.True(route.Latitude.Length <= RouteGeometry.MaxStoredPoints);
    }

    [Fact]
    public async Task CreateRoute_ShouldIgnoreTheLineInTheRequest_WhenARideIsNamed()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);
        await AddZoneAsync(world.Rider.Client, 46.0, 11.0, 500);
        var request = LineRequest();
        request.RideId = rideId;

        var route = await CreateRouteAsync(world.Rider.Client, request);

        // The server took the ride, not the points a client could send to dodge the privacy rules.
        Assert.All(route.Latitude, latitude => Assert.True(latitude > 46.004));
        Assert.InRange(route.DistanceM, 4_200, 4_400);
    }

    [Fact]
    public async Task GetRideRouteDraft_ShouldAnswerNotFound_WhenTheRideIsAnotherMembers()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);

        Assert.Equal(HttpStatusCode.NotFound, (await world.Coach.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await world.OtherRider.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await world.Loner.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct)).StatusCode);
        var stolen = await world.Coach.Client.PostAsJsonAsync(
            "/api/v1/routes", new CreateRouteRequest { RideId = rideId, Name = "Mine now", Surface = "road" }, Ct);
        Assert.Equal(HttpStatusCode.NotFound, stolen.StatusCode);
    }

    [Fact]
    public async Task GetRideRouteDraft_ShouldAnswerNotFound_WhenTheMemberHasNoClub()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Loner.Client);

        Assert.Equal(HttpStatusCode.NotFound, (await world.Loner.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct)).StatusCode);
    }

    [Fact]
    public async Task GetRideRouteDraft_ShouldExplain_WhenRideHasNothingLeftToShare()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);
        await AddZoneAsync(world.Rider.Client, 46.02, 11.0, 1609);

        var response = await world.Rider.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct);

        // A zone around the middle leaves both ends, so a line remains.
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        await AddZoneAsync(world.Rider.Client, 46.0, 11.0, 1609);
        await AddZoneAsync(world.Rider.Client, 46.04, 11.0, 1609);
        Assert.Equal(HttpStatusCode.Conflict, (await world.Rider.Client.GetAsync($"/api/v1/rides/{rideId}/route-draft", Ct)).StatusCode);
    }

    [Fact]
    public async Task ReadGpxRouteDraft_ShouldReturnTheLine_WhenTheFileIsAGpxTrack()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);

        var form = new MultipartFormDataContent { { new ByteArrayContent(Encoding.UTF8.GetBytes(Gpx("Valley", 12))), "file", "valley.gpx" } };
        var response = await world.Rider.Client.PostAsync("/api/v1/routes/gpx-draft", form, Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var draft = (await response.Content.ReadFromJsonAsync<RouteDraftResponse>(Ct))!;
        Assert.Equal("Valley", draft.Name);
        Assert.Equal(12, draft.Latitude.Length);
        Assert.InRange(draft.DistanceM, 1_200, 1_400);
        Assert.InRange(draft.ClimbingM!.Value, 30, 60);

        // The member confirms with what the draft showed; the server measures it again and gets the same numbers.
        var created = await CreateRouteAsync(world.Rider.Client, new CreateRouteRequest
        {
            Name = draft.Name!,
            Surface = "mixed",
            Latitude = draft.Latitude,
            Longitude = draft.Longitude,
            Elevation = draft.Elevation,
        });
        Assert.Equal(draft.DistanceM, created.DistanceM, 3);
        Assert.Equal(draft.ClimbingM, created.ClimbingM);
    }

    [Theory]
    [InlineData("not a gpx file")]
    [InlineData("<gpx><trk><trkseg><trkpt lat=\"46\" lon=\"11\"/></trkseg></trk></gpx>")]
    [InlineData("<gpx><trk><trkseg><trkpt lat=\"46\" lon=\"11\"/><trkpt lat=\"46.0001\" lon=\"11\"/></trkseg></trk></gpx>")]
    public async Task ReadGpxRouteDraft_ShouldRefuse_WhenTheFileIsNotAUsableRoute(string text)
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);

        var form = new MultipartFormDataContent { { new ByteArrayContent(Encoding.UTF8.GetBytes(text)), "file", "bad.gpx" } };

        Assert.Equal(HttpStatusCode.BadRequest, (await world.Rider.Client.PostAsync("/api/v1/routes/gpx-draft", form, Ct)).StatusCode);
    }

    [Fact]
    public async Task ReadGpxRouteDraft_ShouldAnswerNotFound_WhenTheMemberHasNoClub()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);

        var form = new MultipartFormDataContent { { new ByteArrayContent(Encoding.UTF8.GetBytes(Gpx("Valley"))), "file", "valley.gpx" } };

        Assert.Equal(HttpStatusCode.NotFound, (await world.Loner.Client.PostAsync("/api/v1/routes/gpx-draft", form, Ct)).StatusCode);
    }

    [Fact]
    public async Task CreateRoute_ShouldRefuse_WhenTheRequestIsNotARoute()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var client = world.Rider.Client;

        var noName = LineRequest(name: " ");
        var badSurface = LineRequest(surface: "moon");
        var tooShort = new CreateRouteRequest { Name = "Tiny", Surface = "road", Latitude = [46.0, 46.0001], Longitude = [11.0, 11.0] };
        var ragged = LineRequest();
        ragged.Longitude = ragged.Longitude![..5];
        var offPlanet = LineRequest();
        offPlanet.Latitude![3] = 123;
        var raggedElevation = LineRequest();
        raggedElevation.Elevation = [1, 2, 3];
        var noLine = new CreateRouteRequest { Name = "Nothing", Surface = "road" };

        foreach (var request in new[] { noName, badSurface, tooShort, ragged, offPlanet, raggedElevation, noLine })
            Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/v1/routes", request, Ct)).StatusCode);
    }

    [Fact]
    public async Task CreateRoute_ShouldAnswerNotFound_WhenTheMemberHasNoClub()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);

        Assert.Equal(HttpStatusCode.NotFound, (await world.Loner.Client.PostAsJsonAsync("/api/v1/routes", LineRequest(), Ct)).StatusCode);
    }

    [Fact]
    public async Task CreateRoute_ShouldThinTheLine_WhenItHasManyPoints()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        const int count = 4000;
        var request = new CreateRouteRequest
        {
            Name = "Dense",
            Surface = "road",
            Latitude = [.. Enumerable.Range(0, count).Select(i => 46.0 + i * 0.00002)],
            Longitude = [.. Enumerable.Range(0, count).Select(i => 11.0 + Math.Sin(i / 150.0) * 0.003)],
        };

        var route = await CreateRouteAsync(world.Rider.Client, request);

        Assert.InRange(route.Latitude.Length, 20, RouteGeometry.MaxStoredPoints);
        Assert.Equal(request.Latitude[0], route.Latitude[0]);
        Assert.Equal(request.Latitude[^1], route.Latitude[^1]);
        // The distance is the original line's, not the thinned one's.
        Assert.True(route.DistanceM > 8_000);
    }

    [Fact]
    public async Task ListRoutes_ShouldSortAndFilter_WhenAskedTo()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        await CreateRouteAsync(world.Rider.Client, LineRequest("Medium", "road", 10));
        await CreateRouteAsync(world.Coach.Client, LineRequest("Long", "gravel", 20));
        await CreateRouteAsync(world.Owner.Client, LineRequest("Short", "road", 4));

        async Task<string[]> NamesAsync(string query) =>
            (await world.Rider.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes" + query, Ct))!.Routes.Select(r => r.Name).ToArray();

        Assert.Equal(["Short", "Long", "Medium"], await NamesAsync(""));
        Assert.Equal(["Long", "Medium", "Short"], await NamesAsync("?sort=longest"));
        Assert.Equal(["Short", "Medium", "Long"], await NamesAsync("?sort=shortest"));
        Assert.Equal(["Medium", "Short"], (await NamesAsync("?surface=road&sort=longest")));
        Assert.Equal(["Long"], await NamesAsync("?surface=gravel"));
        Assert.Equal(HttpStatusCode.BadRequest, (await world.Rider.Client.GetAsync("/api/v1/routes?sort=best", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await world.Rider.Client.GetAsync("/api/v1/routes?surface=moon", Ct)).StatusCode);
    }

    [Fact]
    public async Task Routes_ShouldNotBeVisible_WhenRequestComesFromAnotherClubOrNoClub()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        var id = route.Id;

        foreach (var outsider in new[] { world.OtherRider, world.OtherOwner, world.Loner })
        {
            var client = outsider.Client;
            Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/v1/routes/{id}", Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.PostAsync($"/api/v1/routes/{id}/gpx-link", null, Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.PutAsJsonAsync($"/api/v1/routes/{id}", new UpdateRouteRequest { Name = "x", Surface = "road" }, Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.PostAsync($"/api/v1/routes/{id}/share", null, Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.DeleteAsync($"/api/v1/routes/{id}/share", Ct)).StatusCode);
            Assert.Equal(HttpStatusCode.NotFound, (await client.DeleteAsync($"/api/v1/routes/{id}", Ct)).StatusCode);

            var mine = await client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes/mine", Ct);
            Assert.Empty(mine!.Routes);
        }

        // Another club's library is its own, and a rider with no club has none.
        Assert.Empty((await world.OtherRider.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes);
        Assert.Equal(HttpStatusCode.NotFound, (await world.Loner.Client.GetAsync("/api/v1/routes", Ct)).StatusCode);

        // Nothing changed.
        var stillThere = await world.Rider.Client.GetFromJsonAsync<RouteDetailResponse>($"/api/v1/routes/{id}", Ct);
        Assert.Equal("Lake loop", stillThere!.Name);
        Assert.True(stillThere.IsShared);
    }

    [Fact]
    public async Task Routes_ShouldBeOpenToTheClub_WhenAMemberSharedThem()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);

        var seenByCoach = await world.Coach.Client.GetFromJsonAsync<RouteDetailResponse>($"/api/v1/routes/{route.Id}", Ct);
        var library = await world.Owner.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct);

        Assert.Equal("Rita Rider", seenByCoach!.OwnerName);
        Assert.False(seenByCoach.IsMine);
        Assert.Equal(route.Latitude.Length, seenByCoach.Latitude.Length);
        Assert.Single(library!.Routes);
        Assert.Equal(route.DistanceM, library.Routes[0].DistanceM);

        // Opening someone's route is not a view of their ride: the sharing log stays empty.
        await using var scope = api.Services.CreateAsyncScope();
        Assert.False(await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().ShareViews.AnyAsync(Ct));
    }

    [Fact]
    public async Task UpdateRoute_ShouldChangeTheDetails_WhenTheOwnerEditsAndRefuseEveryoneElse()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        static UpdateRouteRequest Edit(string name = " Lake loop, clockwise ", string surface = "gravel") =>
            new() { Name = name, Surface = surface, Description = "Dirt after the bridge" };

        var changed = await world.Rider.Client.PutAsJsonAsync($"/api/v1/routes/{route.Id}", Edit(), Ct);

        Assert.Equal(HttpStatusCode.OK, changed.StatusCode);
        var summary = (await changed.Content.ReadFromJsonAsync<RouteSummaryResponse>(Ct))!;
        Assert.Equal(("Lake loop, clockwise", "gravel", "Dirt after the bridge"), (summary.Name, summary.Surface, summary.Description));
        // The club's owner and coaches can remove a route from the library, never edit what a member wrote.
        Assert.Equal(HttpStatusCode.Forbidden, (await world.Owner.Client.PutAsJsonAsync($"/api/v1/routes/{route.Id}", Edit(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await world.Coach.Client.PutAsJsonAsync($"/api/v1/routes/{route.Id}", Edit("Mine"), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await world.Rider.Client.PutAsJsonAsync($"/api/v1/routes/{route.Id}", Edit(surface: "sand"), Ct)).StatusCode);
        Assert.Equal("Lake loop, clockwise", (await world.Owner.Client.GetFromJsonAsync<RouteDetailResponse>($"/api/v1/routes/{route.Id}", Ct))!.Name);
    }

    [Fact]
    public async Task UnshareRoute_ShouldKeepTheRouteWithItsOwner_WhenTheClubOwnerRemovesIt()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);

        // A coach moderates nothing; the member who is not the owner cannot remove it either.
        Assert.Equal(HttpStatusCode.Forbidden, (await world.Coach.Client.DeleteAsync($"/api/v1/routes/{route.Id}/share", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await world.Owner.Client.DeleteAsync($"/api/v1/routes/{route.Id}/share", Ct)).StatusCode);

        Assert.Empty((await world.Coach.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes);
        Assert.Equal(HttpStatusCode.NotFound, (await world.Coach.Client.GetAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);
        var mine = (await world.Rider.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes/mine", Ct))!.Routes;
        Assert.Single(mine);
        Assert.False(mine[0].IsShared);
        Assert.Equal(HttpStatusCode.OK, (await world.Rider.Client.GetAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);

        // The owner can put it back.
        Assert.Equal(HttpStatusCode.OK, (await world.Rider.Client.PostAsync($"/api/v1/routes/{route.Id}/share", null, Ct)).StatusCode);
        Assert.Single((await world.Coach.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes);
    }

    [Fact]
    public async Task UnshareRoute_ShouldWithdrawTheRoute_WhenTheOwnerAsks()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);

        Assert.Equal(HttpStatusCode.NoContent, (await world.Rider.Client.DeleteAsync($"/api/v1/routes/{route.Id}/share", Ct)).StatusCode);

        Assert.Empty((await world.Owner.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes);
        // Share with someone else's route: the coach cannot put the rider's route back.
        Assert.Equal(HttpStatusCode.NotFound, (await world.Coach.Client.PostAsync($"/api/v1/routes/{route.Id}/share", null, Ct)).StatusCode);
    }

    [Fact]
    public async Task DeleteRoute_ShouldRemoveItForGood_WhenTheOwnerDeletesAndRefuseTheClub()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);

        Assert.Equal(HttpStatusCode.Forbidden, (await world.Owner.Client.DeleteAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await world.Rider.Client.DeleteAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.NotFound, (await world.Rider.Client.GetAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.Routes.AnyAsync(Ct));
        Assert.False(await db.RouteLines.AnyAsync(Ct));
    }

    [Fact]
    public async Task LeaveClub_ShouldEndTheShareButKeepTheRoute_WhenTheOwnerLeaves()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);

        (await world.Rider.Client.PostAsync("/api/v1/club/leave", null, Ct)).EnsureSuccessStatusCode();

        Assert.Empty((await world.Coach.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes);
        Assert.Equal(HttpStatusCode.NotFound, (await world.Coach.Client.GetAsync($"/api/v1/routes/{route.Id}", Ct)).StatusCode);
        var mine = (await world.Rider.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes/mine", Ct))!.Routes;
        Assert.False(Assert.Single(mine).IsShared);
        Assert.Equal(HttpStatusCode.NotFound, (await world.Rider.Client.GetAsync("/api/v1/routes", Ct)).StatusCode);
    }

    [Fact]
    public async Task DownloadRoute_ShouldServeGpx_WhenTheLinkComesFromAClubMember()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client, LineRequest("Lake loop & more"));

        var link = (await (await world.Coach.Client.PostAsync($"/api/v1/routes/{route.Id}/gpx-link", null, Ct))
            .Content.ReadFromJsonAsync<RouteDownloadLinkResponse>(Ct))!;
        var file = await api.CreateClient().GetAsync(link.Path, Ct);

        Assert.Equal(HttpStatusCode.OK, file.StatusCode);
        Assert.Equal("application/gpx+xml", file.Content.Headers.ContentType!.MediaType);
        Assert.EndsWith(".gpx", file.Content.Headers.ContentDisposition!.FileNameStar ?? file.Content.Headers.ContentDisposition.FileName);
        var draft = RouteGeometry.ReadGpx(await file.Content.ReadAsByteArrayAsync(Ct));
        Assert.Equal("Lake loop & more", draft.Name);
        Assert.Equal(route.Latitude.Length, draft.Points.Count);
        Assert.Equal(route.Elevation![3], draft.Points[3].Elevation!.Value, 0.1);
    }

    [Fact]
    public async Task DownloadRoute_ShouldRefuse_WhenTheLinkIsForgedExpiredOrNoLongerAllowed()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var route = await CreateRouteAsync(world.Rider.Client);
        var link = (await (await world.Coach.Client.PostAsync($"/api/v1/routes/{route.Id}/gpx-link", null, Ct))
            .Content.ReadFromJsonAsync<RouteDownloadLinkResponse>(Ct))!;
        var anonymous = api.CreateClient();

        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/v1/routes/downloads/not-a-token", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync(link.Path[..^3] + "abc", Ct)).StatusCode);

        var protector = api.Services.GetRequiredService<IDataProtectionProvider>().CreateProtector("velomine.route-download").ToTimeLimitedDataProtector();
        var expired = protector.Protect($"{world.Coach.Id:N}.{route.Id:N}", DateTimeOffset.UtcNow.AddMinutes(-1));
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/v1/routes/downloads/" + Uri.EscapeDataString(expired), Ct)).StatusCode);

        // A link made for a member of another club works for nobody: access is checked when it is used.
        var forged = protector.Protect($"{world.OtherRider.Id:N}.{route.Id:N}", DateTimeOffset.UtcNow.AddMinutes(1));
        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync("/api/v1/routes/downloads/" + Uri.EscapeDataString(forged), Ct)).StatusCode);
        var loner = protector.Protect($"{world.Loner.Id:N}.{route.Id:N}", DateTimeOffset.UtcNow.AddMinutes(1));
        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync("/api/v1/routes/downloads/" + Uri.EscapeDataString(loner), Ct)).StatusCode);

        // The coach leaves; the link they already hold stops working.
        Assert.Equal(HttpStatusCode.OK, (await anonymous.GetAsync(link.Path, Ct)).StatusCode);
        (await world.Coach.Client.PostAsync("/api/v1/club/leave", null, Ct)).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync(link.Path, Ct)).StatusCode);
    }

    [Fact]
    public async Task AccountExport_ShouldIncludeRoutesAsGpx_WhenTheMemberHasRoutes()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        await CreateRouteAsync(world.Rider.Client, LineRequest("Lake loop"));
        await CreateRouteAsync(world.Coach.Client, LineRequest("Coach secret"));
        (await world.Rider.Client.DeleteAsync($"/api/v1/routes/{(await world.Rider.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes/mine", Ct))!.Routes[0].Id}/share", Ct)).EnsureSuccessStatusCode();

        var link = (await (await world.Rider.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct)).Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!;
        var zip = new ZipArchive(await (await api.CreateClient().GetAsync(link.Path, Ct)).Content.ReadAsStreamAsync(Ct));

        var gpx = Assert.Single(zip.Entries, e => e.FullName.StartsWith("routes/", StringComparison.Ordinal) && e.FullName.EndsWith(".gpx", StringComparison.Ordinal));
        using var reader = new StreamReader(gpx.Open());
        Assert.Contains("<trkpt", await reader.ReadToEndAsync(Ct));
        var json = JsonDocument.Parse(await new StreamReader(zip.GetEntry("routes.json")!.Open()).ReadToEndAsync(Ct)).RootElement;
        Assert.Equal(1, json.GetArrayLength());
        Assert.Equal("Lake loop", json[0].GetProperty("name").GetString());
        Assert.False(json[0].GetProperty("sharedWithClub").GetBoolean());
    }

    [Fact]
    public async Task DeleteMyAccount_ShouldRemoveTheMembersRoutes_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        await CreateRouteAsync(world.Rider.Client);
        await CreateRouteAsync(world.Coach.Client, LineRequest("Coach loop"));

        (await world.Rider.Client.PostAsJsonAsync("/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct)).EnsureSuccessStatusCode();

        var library = (await world.Coach.Client.GetFromJsonAsync<RouteListResponse>("/api/v1/routes", Ct))!.Routes;
        Assert.Equal(["Coach loop"], library.Select(r => r.Name));
        await using var scope = api.Services.CreateAsyncScope();
        Assert.Equal(1, await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().RouteLines.CountAsync(Ct));
    }

    [Fact]
    public async Task Routes_ShouldRequireSignIn_WhenCalledWithoutAToken()
    {
        await using var api = await StartAsync(postgres);
        var anonymous = api.CreateClient();
        var id = Guid.NewGuid();

        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/v1/routes", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/v1/routes/mine", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync($"/api/v1/routes/{id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.PostAsJsonAsync("/api/v1/routes", LineRequest(), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync($"/api/v1/rides/{id}/route-draft", Ct)).StatusCode);
    }
}
