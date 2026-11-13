using System.Net;
using System.Net.Http.Json;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Routes.RoutesTestKit;

namespace Velomine.Server.Tests.Clubs;

/// <summary>
/// One club's owner, coach or admin acts on another club's member by id. Every route that takes a member or a
/// request id checks which club it belongs to; these are the calls a stranger could make with a guessed id.
/// </summary>
public sealed class ClubCrossClubTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task JoinRequests_ShouldNotBeDeclinedByAnotherClubsOwner_WhenTheIdIsKnown()
    {
        await using var api = await StartAsync(postgres);
        var first = await NewMemberAsync(api, "First Owner");
        var second = await NewMemberAsync(api, "Second Owner");
        var firstClub = await CreateClubAsync(api, first);
        await CreateClubAsync(api, second);
        // The first club is discoverable, so a stranger may ask to join it.
        (await first.Client.PutAsJsonAsync("/api/v1/club/location",
            new SetClubLocationRequest { Latitude = 45.4642, Longitude = 9.19, IsDiscoverable = true }, Ct)).EnsureSuccessStatusCode();
        var asker = await NewMemberAsync(api, "Asker");
        (await asker.Client.PostAsJsonAsync("/api/v1/club/join-request",
            new RequestToJoinRequest { ClubId = firstClub.Id }, Ct)).EnsureSuccessStatusCode();
        var request = Assert.Single((await first.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);

        // The other club's owner knows the request id; it is not his to decline.
        var declined = await second.Client.PostAsync($"/api/v1/club/join-requests/{request.Id}/decline", null, Ct);

        Assert.Equal(HttpStatusCode.NotFound, declined.StatusCode);
        Assert.Single((await first.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);
    }

    [Fact]
    public async Task ClubMemberRole_ShouldNotBeChangedByAnotherClubsOwner_WhenTheMemberIsReal()
    {
        await using var api = await StartAsync(postgres);
        var first = await NewMemberAsync(api, "First Owner");
        var second = await NewMemberAsync(api, "Second Owner");
        var firstClub = await CreateClubAsync(api, first);
        await CreateClubAsync(api, second);
        var rider = await NewMemberAsync(api, "Rider");
        await JoinAsync(rider, firstClub);

        // A real member of the other club, not a random id.
        var changed = await second.Client.PutAsJsonAsync(
            $"/api/v1/club/members/{rider.Id}/role",
            new SetClubMemberRoleRequest { Role = ClubRoles.Coach },
            Ct);

        Assert.Equal(HttpStatusCode.NotFound, changed.StatusCode);
        var mine = await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct);
        Assert.Equal("member", mine!.Club!.MyRole);
    }

    [Fact]
    public async Task CoachViews_ShouldGiveNothingToACoachOfAnotherClub_WhenTheyKnowTheRideId()
    {
        await using var api = await StartAsync(postgres);
        var world = await NewWorldAsync(api);
        var rideId = await UploadRideAsync(world.Rider.Client);
        (await world.Rider.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "coaches" }, Ct)).EnsureSuccessStatusCode();

        // A member of the other club, who shares with everyone in their own club.
        var intruder = world.OtherRider.Client;
        var athlete = $"/api/v1/clubs/{world.Club.Id}/athletes/{world.Rider.Id}";
        foreach (var path in new[]
                 {
                     athlete,
                     $"{athlete}/rides",
                     $"{athlete}/rides/{rideId}",
                     $"{athlete}/rides/{rideId}/streams",
                     $"{athlete}/rides/{rideId}/laps",
                     $"{athlete}/power-curve",
                     $"{athlete}/wellbeing",
                 })
        {
            var response = await intruder.GetAsync(path, Ct);
            Assert.True(
                response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.Forbidden,
                $"{path} answered {(int)response.StatusCode} to a member of another club.");
        }
    }
}
