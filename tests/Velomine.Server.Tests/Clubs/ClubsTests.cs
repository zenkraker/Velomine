using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Tests.Clubs;

[Collection("postgres")]
public sealed class ClubsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> AdminAsync(TestApi api) =>
        api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private sealed record Member(string Email, Guid Id, HttpClient Client);

    private static async Task<Member> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        var id = (await (await api.RegisterAsync(email)).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;
        return new Member(email, id, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task<AdminClubResponse> CreateClubAsync(
        HttpClient admin,
        string name,
        string ownerEmail)
    {
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = name, OwnerEmail = ownerEmail },
            Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    private static async Task<ClubResponse> MyClubAsync(HttpClient client)
    {
        var my = await client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct);
        Assert.NotNull(my!.Club);
        return my.Club!;
    }

    [Fact]
    public async Task Clubs_ShouldRequireAnAdminAndAFreeOwner_WhenCreatingAClub()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var name = $"Club {Guid.NewGuid():N}";

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/admin/clubs", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await owner.Client.GetAsync("/api/v1/admin/clubs", Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await owner.Client.PostAsJsonAsync("/api/v1/admin/clubs", new CreateClubRequest { Name = name, OwnerEmail = owner.Email }, Ct)).StatusCode);

        var missing = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = name, OwnerEmail = TestApi.NewEmail() },
            Ct);
        Assert.Equal(HttpStatusCode.BadRequest, missing.StatusCode);

        var club = await CreateClubAsync(admin, name, owner.Email);
        Assert.NotEmpty(club.JoinCode);
        Assert.Equal(1, club.MemberCount);
        Assert.Equal(owner.Id, club.OwnerId);
        Assert.Equal(owner.Email, club.OwnerEmail);

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await admin.PostAsJsonAsync("/api/v1/admin/clubs", new CreateClubRequest { Name = name, OwnerEmail = (await NewMemberAsync(api)).Email }, Ct)).StatusCode);

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await admin.PostAsJsonAsync("/api/v1/admin/clubs", new CreateClubRequest { Name = $"{name} 2", OwnerEmail = owner.Email }, Ct)).StatusCode);

        var list = (await admin.GetFromJsonAsync<AdminClubListResponse>("/api/v1/admin/clubs", Ct))!.Clubs;
        Assert.Contains(list, c => c.Id == club.Id && c.Name == name);
    }

    [Fact]
    public async Task Clubs_ShouldJoinAndHideTheCode_WhenUsingTheJoinCode()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);

        var asOwner = await MyClubAsync(owner.Client);
        Assert.Equal(ClubRoles.Owner, asOwner.MyRole);
        Assert.Equal(club.JoinCode, asOwner.JoinCode);
        Assert.Single(asOwner.Members);

        var rider = await NewMemberAsync(api);
        var joined = await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode.ToLowerInvariant() }, Ct);
        Assert.Equal(HttpStatusCode.OK, joined.StatusCode);

        var asRider = await MyClubAsync(rider.Client);
        Assert.Equal(ClubRoles.Member, asRider.MyRole);
        Assert.Null(asRider.JoinCode);
        Assert.Equal(2, asRider.Members.Length);
        Assert.Contains(asRider.Members, m => m.UserId == rider.Id);

        var again = await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);
        Assert.Equal(HttpStatusCode.Conflict, again.StatusCode);

        var stranger = await NewMemberAsync(api);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await stranger.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = "WRONG123" }, Ct)).StatusCode);

        var secondOwner = await NewMemberAsync(api);
        var second = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", secondOwner.Email);
        Assert.NotEqual(club.JoinCode, second.JoinCode);
        Assert.Equal(
            HttpStatusCode.Conflict,
            (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = second.JoinCode }, Ct)).StatusCode);
    }

    [Fact]
    public async Task Clubs_ShouldTakeNoNewJoins_WhenTheClubIsDisabled()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var somebody = await NewMemberAsync(api);

        var none = await somebody.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct);
        Assert.Null(none!.Club);

        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);

        var disabled = await admin.PutAsJsonAsync(
            $"/api/v1/admin/clubs/{club.Id}",
            new UpdateClubRequest { Name = club.Name, IsActive = false },
            Ct);
        Assert.Equal(HttpStatusCode.OK, disabled.StatusCode);

        Assert.False((await MyClubAsync(owner.Client)).IsActive);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await somebody.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).StatusCode);

        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await owner.Client.GetAsync("/api/v1/admin/clubs", Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await owner.Client.PutAsJsonAsync($"/api/v1/admin/clubs/{club.Id}", new UpdateClubRequest { Name = club.Name, IsActive = true }, Ct)).StatusCode);
    }

    [Fact]
    public async Task Clubs_ShouldLetOnlyTheOwnerPromoteAndRotate_WhenManagingTheClub()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        var rider = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);
        await other.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);

        var promoted = await owner.Client.PutAsJsonAsync(
            $"/api/v1/club/members/{rider.Id}/role",
            new SetClubMemberRoleRequest { Role = ClubRoles.Coach },
            Ct);
        Assert.Equal(HttpStatusCode.OK, promoted.StatusCode);
        Assert.Equal(ClubRoles.Coach, (await promoted.Content.ReadFromJsonAsync<ClubMemberResponse>(Ct))!.Role);

        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await rider.Client.PutAsJsonAsync($"/api/v1/club/members/{other.Id}/role", new SetClubMemberRoleRequest { Role = ClubRoles.Coach }, Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.Forbidden, (await rider.Client.PostAsync("/api/v1/club/join-code", null, Ct)).StatusCode);

        var rotated = await owner.Client.PostAsync("/api/v1/club/join-code", null, Ct);
        rotated.EnsureSuccessStatusCode();
        var newCode = (await rotated.Content.ReadFromJsonAsync<JoinCodeResponse>(Ct))!.JoinCode;
        Assert.NotEqual(club.JoinCode, newCode);

        var stranger = await NewMemberAsync(api);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await stranger.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.OK,
            (await stranger.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = newCode }, Ct)).StatusCode);

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await owner.Client.PostAsync("/api/v1/club/leave", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await rider.Client.PostAsync("/api/v1/club/leave", null, Ct)).StatusCode);
        Assert.Null((await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.Club);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await owner.Client.PutAsJsonAsync($"/api/v1/club/members/{other.Id}/role", new SetClubMemberRoleRequest { Role = ClubRoles.Owner }, Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await owner.Client.PutAsJsonAsync($"/api/v1/club/members/{Guid.NewGuid()}/role", new SetClubMemberRoleRequest { Role = ClubRoles.Coach }, Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await api.CreateClient().GetAsync("/api/v1/club", Ct)).StatusCode);
    }

    [Fact]
    public async Task Clubs_ShouldMoveOwnership_WhenAnAdminAssignsAnotherMember()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        var rider = await NewMemberAsync(api);
        await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);

        var moved = await admin.PutAsJsonAsync(
            $"/api/v1/admin/clubs/{club.Id}/owner",
            new SetClubOwnerRequest { UserId = rider.Id },
            Ct);
        Assert.Equal(HttpStatusCode.OK, moved.StatusCode);
        Assert.Equal(rider.Id, (await moved.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!.OwnerId);

        Assert.Equal(ClubRoles.Owner, (await MyClubAsync(rider.Client)).MyRole);
        Assert.Equal(ClubRoles.Member, (await MyClubAsync(owner.Client)).MyRole);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.Client.PostAsync("/api/v1/club/leave", null, Ct)).StatusCode);

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await admin.PutAsJsonAsync(
                $"/api/v1/admin/clubs/{club.Id}/owner",
                new SetClubOwnerRequest { UserId = Guid.NewGuid() },
                Ct)).StatusCode);
    }

    private static Task<HttpResponseMessage> SetLocationAsync(
        HttpClient client,
        double? latitude,
        double? longitude,
        bool discoverable) =>
        client.PutAsJsonAsync(
            "/api/v1/club/location",
            new SetClubLocationRequest
            {
                Latitude = latitude,
                Longitude = longitude,
                IsDiscoverable = discoverable,
            },
            Ct);

    private static Task<HttpResponseMessage> AskAsync(HttpClient client, Guid clubId, string? note = null) =>
        client.PostAsJsonAsync("/api/v1/club/join-request", new RequestToJoinRequest { ClubId = clubId, Note = note }, Ct);

    [Fact]
    public async Task ClubLocation_ShouldBeBothOrNeitherAndOwnerOnly_WhenSettingIt()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        var rider = await NewMemberAsync(api);
        await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);

        var saved = await SetLocationAsync(owner.Client, 45.4642, 9.19, true);
        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var mine = await MyClubAsync(owner.Client);
        Assert.Equal(45.4642, mine.Latitude!.Value, 4);
        Assert.Equal(9.19, mine.Longitude!.Value, 4);
        Assert.True(mine.IsDiscoverable);

        Assert.Equal(HttpStatusCode.Forbidden, (await SetLocationAsync(rider.Client, 45, 9, true)).StatusCode);
        var nobody = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.NotFound, (await SetLocationAsync(nobody.Client, 45, 9, true)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetLocationAsync(owner.Client, 45, null, false)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetLocationAsync(owner.Client, null, null, true)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetLocationAsync(owner.Client, 91, 9, false)).StatusCode);
    }

    [Fact]
    public async Task NearbyClubs_ShouldListOnlyNearDiscoverableClubs_WhenGivenAPosition()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);

        var nearOwner = await NewMemberAsync(api);
        var near = await CreateClubAsync(admin, $"Near {Guid.NewGuid():N}", nearOwner.Email);
        await SetLocationAsync(nearOwner.Client, 45.4642, 9.19, true);

        var fartherOwner = await NewMemberAsync(api);
        var farther = await CreateClubAsync(admin, $"Farther {Guid.NewGuid():N}", fartherOwner.Email);
        await SetLocationAsync(fartherOwner.Client, 45.5, 9.3, true);

        var hiddenOwner = await NewMemberAsync(api);
        var hidden = await CreateClubAsync(admin, $"Hidden {Guid.NewGuid():N}", hiddenOwner.Email);
        await SetLocationAsync(hiddenOwner.Client, 45.4642, 9.19, false);

        var farOwner = await NewMemberAsync(api);
        var far = await CreateClubAsync(admin, $"Far {Guid.NewGuid():N}", farOwner.Email);
        await SetLocationAsync(farOwner.Client, 41.9, 12.5, true);

        var rider = await NewMemberAsync(api);
        var response = await rider.Client.PostAsJsonAsync(
            "/api/v1/club/nearby",
            new NearbyClubsRequest { Latitude = 45.4642, Longitude = 9.19, RadiusKm = 50 },
            Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var found = (await response.Content.ReadFromJsonAsync<NearbyClubsResponse>(Ct))!;

        Assert.Equal(2, found.Clubs.Length);
        Assert.Equal(near.Id, found.Clubs[0].Id);
        Assert.Equal(farther.Id, found.Clubs[1].Id);
        Assert.DoesNotContain(found.Clubs, c => c.Id == hidden.Id);
        Assert.DoesNotContain(found.Clubs, c => c.Id == far.Id);

        var body = await response.Content.ReadAsStringAsync(Ct);
        Assert.DoesNotContain("latitude", body);
        Assert.DoesNotContain("longitude", body);

        var close = await rider.Client.PostAsJsonAsync(
            "/api/v1/club/nearby",
            new NearbyClubsRequest { Latitude = 45.4642, Longitude = 9.19, RadiusKm = 1 },
            Ct);
        Assert.Single((await close.Content.ReadFromJsonAsync<NearbyClubsResponse>(Ct))!.Clubs);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await rider.Client.PostAsJsonAsync(
                "/api/v1/club/nearby",
                new NearbyClubsRequest { Latitude = 45.4642, Longitude = 9.19, RadiusKm = 500 },
                Ct)).StatusCode);

        Assert.Equal(
            HttpStatusCode.Conflict,
            (await nearOwner.Client.PostAsJsonAsync(
                "/api/v1/club/nearby",
                new NearbyClubsRequest { Latitude = 45.4642, Longitude = 9.19, RadiusKm = 50 },
                Ct)).StatusCode);
    }

    [Fact]
    public async Task JoinRequests_ShouldJoinTheRiderAndNotifyBoth_WhenTheOwnerApproves()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        await SetLocationAsync(owner.Client, 45.4642, 9.19, true);
        var rider = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.OK, (await AskAsync(rider.Client, club.Id, "May I join?")).StatusCode);
        var pending = (await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!;
        Assert.NotNull(pending.Request);
        Assert.Equal(club.Id, pending.Request!.ClubId);
        Assert.Equal("May I join?", pending.Request.Note);

        var ownerNotes = (await owner.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!;
        Assert.Contains(ownerNotes.Notifications, n => n.Type == NotificationTypes.ClubJoinRequest);

        var listed = (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!;
        var request = Assert.Single(listed.Requests);
        Assert.Equal(rider.Id, request.UserId);

        var approved = await owner.Client.PostAsync($"/api/v1/club/join-requests/{request.Id}/approve", null, Ct);
        Assert.Equal(HttpStatusCode.NoContent, approved.StatusCode);

        var mine = await MyClubAsync(rider.Client);
        Assert.Equal(ClubRoles.Member, mine.MyRole);
        Assert.Empty((await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);
        Assert.Null((await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!.Request);

        var riderNotes = (await rider.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!;
        Assert.Contains(riderNotes.Notifications, n => n.Type == NotificationTypes.ClubJoinApproved && n.Subject == club.Name);
    }

    [Fact]
    public async Task JoinRequests_ShouldBeOwnerOnlyAndOpenOnly_WhenManagingThem()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        var rider = await NewMemberAsync(api);
        await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct);
        await owner.Client.PutAsJsonAsync(
            $"/api/v1/club/members/{rider.Id}/role",
            new SetClubMemberRoleRequest { Role = ClubRoles.Coach },
            Ct);

        Assert.Equal(HttpStatusCode.Forbidden, (await rider.Client.GetAsync("/api/v1/club/join-requests", Ct)).StatusCode);

        var outsider = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.NotFound, (await outsider.Client.GetAsync("/api/v1/club/join-requests", Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await AskAsync(outsider.Client, club.Id)).StatusCode);

        Assert.Equal(HttpStatusCode.Conflict, (await AskAsync(rider.Client, club.Id)).StatusCode);

        await SetLocationAsync(owner.Client, 45.4642, 9.19, true);
        var asker = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await AskAsync(asker.Client, club.Id)).StatusCode);
        var request = Assert.Single(
            (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);

        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await rider.Client.PostAsync($"/api/v1/club/join-requests/{request.Id}/approve", null, Ct)).StatusCode);
        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await rider.Client.PostAsync($"/api/v1/club/join-requests/{request.Id}/decline", null, Ct)).StatusCode);
    }

    [Fact]
    public async Task JoinRequests_ShouldReplaceThePendingAsk_WhenAskingAnotherClub()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var firstOwner = await NewMemberAsync(api);
        var first = await CreateClubAsync(admin, $"First {Guid.NewGuid():N}", firstOwner.Email);
        await SetLocationAsync(firstOwner.Client, 45.4642, 9.19, true);
        var secondOwner = await NewMemberAsync(api);
        var second = await CreateClubAsync(admin, $"Second {Guid.NewGuid():N}", secondOwner.Email);
        await SetLocationAsync(secondOwner.Client, 45.5, 9.3, true);

        var rider = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await AskAsync(rider.Client, first.Id)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await AskAsync(rider.Client, second.Id)).StatusCode);

        var pending = (await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!;
        Assert.Equal(second.Id, pending.Request!.ClubId);
        Assert.Empty((await firstOwner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);
        Assert.Single((await secondOwner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);

        Assert.Equal(HttpStatusCode.NoContent, (await rider.Client.DeleteAsync("/api/v1/club/join-request", Ct)).StatusCode);
        Assert.Null((await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!.Request);
    }

    [Fact]
    public async Task JoinClub_ShouldWithdrawThePendingAsk_WhenJoiningWithACode()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var openOwner = await NewMemberAsync(api);
        var open = await CreateClubAsync(admin, $"Open {Guid.NewGuid():N}", openOwner.Email);
        await SetLocationAsync(openOwner.Client, 45.4642, 9.19, true);

        var codeOwner = await NewMemberAsync(api);
        var codeClub = await CreateClubAsync(admin, $"Code {Guid.NewGuid():N}", codeOwner.Email);

        var rider = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await AskAsync(rider.Client, open.Id)).StatusCode);
        Assert.Equal(
            HttpStatusCode.OK,
            (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = codeClub.JoinCode }, Ct)).StatusCode);

        Assert.Null((await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!.Request);
        Assert.Empty((await openOwner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);
    }

    [Fact]
    public async Task JoinRequests_ShouldDeclineTheAsk_WhenTheOwnerSaysNo()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, $"Club {Guid.NewGuid():N}", owner.Email);
        await SetLocationAsync(owner.Client, 45.4642, 9.19, true);
        var rider = await NewMemberAsync(api);
        await AskAsync(rider.Client, club.Id);
        var request = Assert.Single(
            (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests);

        Assert.Equal(
            HttpStatusCode.NoContent,
            (await owner.Client.PostAsync($"/api/v1/club/join-requests/{request.Id}/decline", null, Ct)).StatusCode);

        Assert.Null((await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.Club);
        Assert.Null((await rider.Client.GetFromJsonAsync<MyJoinRequestResponse>("/api/v1/club/join-request", Ct))!.Request);
        var riderNotes = (await rider.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!;
        Assert.Contains(riderNotes.Notifications, n => n.Type == NotificationTypes.ClubJoinDeclined && n.Subject == club.Name);
    }
}
