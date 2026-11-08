using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;

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
    public async Task CreatingAClubIsForAdmins_AndTheOwnerMustBeAnAccountWithoutOne()
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
    public async Task MembersJoinWithTheCode_AndOnlyTheOwnerSeesIt()
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
    public async Task AClublessAccountHasNoClub_AndADisabledClubTakesNoNewJoins()
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
    public async Task OnlyTheOwnerPromotesCoaches_AndCanRotateTheCode()
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
    public async Task TheAdminCanMoveOwnershipToAnotherMember()
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
}
