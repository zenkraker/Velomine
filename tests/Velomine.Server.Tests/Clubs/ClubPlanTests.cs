using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests.Clubs;

public sealed class ClubPlanTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(bool clubCreation = false) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        if (clubCreation) b.UseSetting("Velomine:Accounts:ClubCreationEnabled", "true");
    });

    private static Task<HttpClient> AdminAsync(TestApi api) =>
        api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private sealed record Member(string Email, Guid Id, HttpClient Client);

    private static async Task<Member> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        var id = (await (await api.RegisterAsync(email)).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;
        return new Member(email, id, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task<AdminClubResponse> CreateClubAsync(HttpClient admin, string ownerEmail)
    {
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = ownerEmail },
            Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    private static Task<HttpResponseMessage> SetPlanAsync(HttpClient client, Guid clubId, int? limit, DateOnly? until) =>
        client.PutAsJsonAsync($"/api/v1/admin/clubs/{clubId}/plan", new SetClubPlanRequest { MemberLimit = limit, PaidUntil = until }, Ct);

    /// <summary>Sets a plan straight in the database, for limits smaller than the smallest real band.</summary>
    private static async Task SetPlanDirectAsync(TestApi api, Guid clubId, int? limit, DateOnly? until)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        await db.Clubs.Where(c => c.Id == clubId).ExecuteUpdateAsync(
            s => s.SetProperty(c => c.MemberLimit, limit).SetProperty(c => c.PaidUntil, until), Ct);
    }

    private static async Task<ClubResponse?> MyClubOrNullAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.Club;

    private static Task<HttpResponseMessage> JoinAsync(HttpClient client, string code) =>
        client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = code }, Ct);

    private static async Task<string> ProblemAsync(HttpResponseMessage response) => await response.Content.ReadAsStringAsync(Ct);

    private static async Task AskAsync(HttpClient client, Guid clubId)
    {
        var response = await client.PostAsJsonAsync("/api/v1/club/join-request", new RequestToJoinRequest { ClubId = clubId }, Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private static async Task OpenToDiscoveryAsync(HttpClient owner)
    {
        var response = await owner.PutAsJsonAsync(
            "/api/v1/club/location",
            new SetClubLocationRequest { Latitude = 45.0, Longitude = 9.0, IsDiscoverable = true },
            Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private static async Task<Guid> OnlyRequestAsync(HttpClient owner) =>
        Assert.Single((await owner.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests).Id;

    // Starting a club

    [Fact]
    public async Task StartClub_ShouldBeRefused_WhenTheOperatorHasNotTurnedItOn()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api);

        Assert.False((await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.CanStartClub);
        var response = await rider.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "My club", IsDiscoverable = false }, Ct);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Null(await MyClubOrNullAsync(rider.Client));
    }

    [Fact]
    public async Task StartClub_ShouldMakeTheRiderOwnerOnASmallTrialPlan_WhenTheSettingIsOn()
    {
        await using var api = await StartAsync(clubCreation: true);
        var rider = await NewMemberAsync(api);
        Assert.True((await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.CanStartClub);

        var response = await rider.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "Friday Riders", IsDiscoverable = false }, Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var club = (await response.Content.ReadFromJsonAsync<MyClubResponse>(Ct))!.Club!;
        Assert.Equal(ClubRoles.Owner, club.MyRole);
        Assert.NotNull(club.JoinCode);
        Assert.NotNull(club.Plan);
        Assert.Equal(25, club.Plan!.MemberLimit);
        Assert.Equal(1, club.Plan.MemberCount);
        var expected = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(30);
        Assert.InRange(club.Plan.PaidUntil!.Value.DayNumber, expected.DayNumber - 1, expected.DayNumber + 1);
        Assert.Null(club.Plan.Blocked);

        var again = await rider.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "Second club", IsDiscoverable = false }, Ct);
        Assert.Equal(HttpStatusCode.Conflict, again.StatusCode);
        Assert.False((await rider.Client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct))!.CanStartClub);

        var other = await NewMemberAsync(api);
        var clash = await other.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "Friday Riders", IsDiscoverable = false }, Ct);
        Assert.Equal(HttpStatusCode.Conflict, clash.StatusCode);
    }

    [Fact]
    public async Task StartClub_ShouldFollowTheSavedSetting_WhenTheOperatorChangesIt()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var rider = await NewMemberAsync(api);
        var request = new StartClubRequest { Name = "Late starters", IsDiscoverable = false };

        var saved = await admin.PutAsJsonAsync("/api/v1/admin/settings", new UpdateSettingsRequest(true, false, true), Ct);
        Assert.True((await saved.Content.ReadFromJsonAsync<SettingsResponse>(Ct))!.ClubCreationEnabled);
        Assert.Equal(HttpStatusCode.OK, (await rider.Client.PostAsJsonAsync("/api/v1/club", request, Ct)).StatusCode);

        // An older admin screen that leaves the field out does not switch it off.
        var kept = await admin.PutAsJsonAsync("/api/v1/admin/settings", new UpdateSettingsRequest(true, false), Ct);
        Assert.True((await kept.Content.ReadFromJsonAsync<SettingsResponse>(Ct))!.ClubCreationEnabled);
    }

    [Fact]
    public async Task StartClub_ShouldReturn429_WhenOneRiderKeepsTrying()
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.UseSetting("Velomine:Accounts:ClubCreationEnabled", "true");
            b.UseSetting("Velomine:RateLimits:ClubCreationsPerDay", "2");
        });
        var rider = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);

        // Two refused tries (empty name) use up the budget; a third is stopped before it is even read.
        for (var i = 0; i < 2; i++)
            Assert.Equal(HttpStatusCode.BadRequest, (await rider.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "", IsDiscoverable = false }, Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.TooManyRequests, (await rider.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "Real name", IsDiscoverable = false }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await other.Client.PostAsJsonAsync("/api/v1/club", new StartClubRequest { Name = "Other club", IsDiscoverable = false }, Ct)).StatusCode);
    }

    [Fact]
    public async Task CreateClub_ShouldHaveNoPlan_WhenTheOperatorCreatesTheClub()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);

        var club = await CreateClubAsync(await AdminAsync(api), owner.Email);

        Assert.Null(club.MemberLimit);
        Assert.Null(club.PaidUntil);
        Assert.Null((await MyClubOrNullAsync(owner.Client))!.Plan);
    }

    // The limit

    [Fact]
    public async Task JoinClub_ShouldReturn409_WhenTheClubIsFull()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await SetPlanDirectAsync(api, club.Id, 2, null);
        var first = await NewMemberAsync(api);
        var second = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(first.Client, club.JoinCode)).StatusCode);
        var refused = await JoinAsync(second.Client, club.JoinCode);

        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);
        Assert.Contains("full", await ProblemAsync(refused));
        Assert.Null(await MyClubOrNullAsync(second.Client));

        // Moving up a band lets the next rider in.
        Assert.Equal(HttpStatusCode.OK, (await SetPlanAsync(admin, club.Id, 75, null)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(second.Client, club.JoinCode)).StatusCode);
    }

    [Fact]
    public async Task ApproveJoinRequest_ShouldReturn409AndKeepTheRequest_WhenTheClubIsFull()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await OpenToDiscoveryAsync(owner.Client);
        var rider = await NewMemberAsync(api);
        await AskAsync(rider.Client, club.Id);
        await SetPlanDirectAsync(api, club.Id, 1, null);

        var listed = (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!;
        Assert.Equal(ClubPlan.Full, listed.AdmissionBlocked);
        var requestId = Assert.Single(listed.Requests).Id;

        var refused = await owner.Client.PostAsync($"/api/v1/club/join-requests/{requestId}/approve", null, Ct);
        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);
        Assert.Contains("full", await ProblemAsync(refused));
        Assert.Null(await MyClubOrNullAsync(rider.Client));
        Assert.Equal(requestId, await OnlyRequestAsync(owner.Client));

        await SetPlanAsync(admin, club.Id, 25, null);
        Assert.Null((await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.AdmissionBlocked);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.Client.PostAsync($"/api/v1/club/join-requests/{requestId}/approve", null, Ct)).StatusCode);
        Assert.NotNull(await MyClubOrNullAsync(rider.Client));
    }

    [Fact]
    public async Task JoinClub_ShouldNeverPassTheLimit_WhenManyRidersJoinAtTheSameMoment()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await SetPlanDirectAsync(api, club.Id, 4, null);
        var riders = new List<Member>();
        for (var i = 0; i < 10; i++) riders.Add(await NewMemberAsync(api));

        var responses = await Task.WhenAll(riders.Select(r => JoinAsync(r.Client, club.JoinCode)));

        Assert.Equal(3, responses.Count(r => r.StatusCode == HttpStatusCode.OK));
        Assert.Equal(7, responses.Count(r => r.StatusCode == HttpStatusCode.Conflict));
        var members = (await admin.GetFromJsonAsync<AdminClubListResponse>("/api/v1/admin/clubs", Ct))!.Clubs.Single(c => c.Id == club.Id).MemberCount;
        Assert.Equal(4, members);
    }

    [Fact]
    public async Task ApproveJoinRequest_ShouldNeverPassTheLimit_WhenApprovalsRaceWithCodeJoins()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await OpenToDiscoveryAsync(owner.Client);
        var askers = new List<Member>();
        for (var i = 0; i < 4; i++)
        {
            var asker = await NewMemberAsync(api);
            await AskAsync(asker.Client, club.Id);
            askers.Add(asker);
        }

        var joiners = new List<Member>();
        for (var i = 0; i < 4; i++) joiners.Add(await NewMemberAsync(api));
        await SetPlanDirectAsync(api, club.Id, 4, null);
        var requestIds = (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!.Requests.Select(r => r.Id).ToList();

        var approvals = requestIds.Select(id => owner.Client.PostAsync($"/api/v1/club/join-requests/{id}/approve", null, Ct));
        var joins = joiners.Select(j => JoinAsync(j.Client, club.JoinCode));
        var all = await Task.WhenAll(approvals.Concat(joins));

        Assert.Equal(3, all.Count(r => r.IsSuccessStatusCode));
        Assert.Equal(5, all.Count(r => r.StatusCode == HttpStatusCode.Conflict));
        var members = (await admin.GetFromJsonAsync<AdminClubListResponse>("/api/v1/admin/clubs", Ct))!.Clubs.Single(c => c.Id == club.Id).MemberCount;
        Assert.Equal(4, members);
    }

    // An ended plan

    [Fact]
    public async Task Club_ShouldKeepWorkingButTakeNoMembers_WhenThePlanHasEnded()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await OpenToDiscoveryAsync(owner.Client);
        var member = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(member.Client, club.JoinCode)).StatusCode);
        var asker = await NewMemberAsync(api);
        await AskAsync(asker.Client, club.Id);
        var late = await NewMemberAsync(api);
        var yesterday = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(-1);

        Assert.Equal(HttpStatusCode.OK, (await SetPlanAsync(admin, club.Id, 25, yesterday)).StatusCode);

        // Everyone in the club still has the club, its roster and its owner's tools.
        var asMember = (await MyClubOrNullAsync(member.Client))!;
        Assert.Equal(2, asMember.Members.Length);
        Assert.Null(asMember.Plan);
        var asOwner = (await MyClubOrNullAsync(owner.Client))!;
        Assert.True(asOwner.IsActive);
        Assert.Equal(ClubPlan.Ended, asOwner.Plan!.Blocked);
        Assert.Equal(yesterday, asOwner.Plan.PaidUntil);

        var joinRefused = await JoinAsync(late.Client, club.JoinCode);
        Assert.Equal(HttpStatusCode.Conflict, joinRefused.StatusCode);
        Assert.Contains("ended", await ProblemAsync(joinRefused));

        var listed = (await owner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!;
        Assert.Equal(ClubPlan.Ended, listed.AdmissionBlocked);
        var approveRefused = await owner.Client.PostAsync($"/api/v1/club/join-requests/{listed.Requests.Single().Id}/approve", null, Ct);
        Assert.Equal(HttpStatusCode.Conflict, approveRefused.StatusCode);
        Assert.Contains("ended", await ProblemAsync(approveRefused));

        // Asking to join is still allowed, and renewing opens the door again.
        await AskAsync(late.Client, club.Id);
        await SetPlanAsync(admin, club.Id, 25, DateOnly.FromDateTime(DateTime.UtcNow));
        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(late.Client, club.JoinCode)).StatusCode);
    }

    // Who sees and changes a plan

    [Fact]
    public async Task ClubPlan_ShouldStayWithTheServerOperator_WhenAClubAdminTriesToChangeIt()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        var otherOwner = await NewMemberAsync(api);
        var otherClub = await CreateClubAsync(admin, otherOwner.Email);
        var until = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(400);

        Assert.Equal(HttpStatusCode.Unauthorized, (await SetPlanAsync(api.CreateClient(), club.Id, null, until)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await SetPlanAsync(owner.Client, club.Id, null, until)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await SetPlanAsync(owner.Client, otherClub.Id, null, until)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await owner.Client.GetAsync("/api/v1/admin/clubs", Ct)).StatusCode);

        var clubs = (await admin.GetFromJsonAsync<AdminClubListResponse>("/api/v1/admin/clubs", Ct))!.Clubs;
        Assert.All(clubs, c => Assert.Null(c.PaidUntil));
    }

    [Fact]
    public async Task ClubPlan_ShouldBeSetOnlyToABand_WhenTheOperatorSavesIt()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        var until = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(365);

        Assert.Equal(HttpStatusCode.BadRequest, (await SetPlanAsync(admin, club.Id, 30, until)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await SetPlanAsync(admin, Guid.NewGuid(), 25, until)).StatusCode);

        foreach (var band in new int?[] { 25, 75, 150, null })
        {
            var saved = await SetPlanAsync(admin, club.Id, band, until);
            Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
            var body = (await saved.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
            Assert.Equal(band, body.MemberLimit);
            Assert.Equal(until, body.PaidUntil);
            Assert.Equal(1, body.MemberCount);
        }
    }

    [Fact]
    public async Task MyClub_ShouldShowThePlanOnlyToItsOwner_WhenTwoClubsHavePlans()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        var otherOwner = await NewMemberAsync(api);
        var otherClub = await CreateClubAsync(admin, otherOwner.Email);
        var member = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(member.Client, club.JoinCode)).StatusCode);
        var until = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(100);
        await SetPlanAsync(admin, club.Id, 75, until);
        await SetPlanAsync(admin, otherClub.Id, 150, until.AddDays(5));

        var mine = (await MyClubOrNullAsync(owner.Client))!;
        var theirs = (await MyClubOrNullAsync(otherOwner.Client))!;

        Assert.Equal(75, mine.Plan!.MemberLimit);
        Assert.Equal(2, mine.Plan.MemberCount);
        Assert.Equal(until, mine.Plan.PaidUntil);
        Assert.Equal(150, theirs.Plan!.MemberLimit);
        Assert.Equal(1, theirs.Plan.MemberCount);
        Assert.Null((await MyClubOrNullAsync(member.Client))!.Plan);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.Client.GetAsync("/api/v1/club/join-requests", Ct)).StatusCode);
    }

    [Fact]
    public async Task ClubData_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        await OpenToDiscoveryAsync(owner.Client);
        await SetPlanDirectAsync(api, club.Id, 1, null);
        var asker = await NewMemberAsync(api);
        await AskAsync(asker.Client, club.Id);
        var requestId = await OnlyRequestAsync(owner.Client);

        var otherOwner = await NewMemberAsync(api);
        await CreateClubAsync(admin, otherOwner.Email);

        // The other club's owner sees neither the request nor the state of this club's plan, and cannot approve it.
        var theirs = (await otherOwner.Client.GetFromJsonAsync<JoinRequestsResponse>("/api/v1/club/join-requests", Ct))!;
        Assert.Empty(theirs.Requests);
        Assert.Null(theirs.AdmissionBlocked);
        Assert.Equal(HttpStatusCode.NotFound, (await otherOwner.Client.PostAsync($"/api/v1/club/join-requests/{requestId}/approve", null, Ct)).StatusCode);
        Assert.Null((await MyClubOrNullAsync(otherOwner.Client))!.Plan);
    }

    // Notices

    private async Task<(TestApi Api, Member Owner, Member Member, AdminClubResponse Club)> ClubWithPlanAsync()
    {
        var api = await StartAsync();
        var admin = await AdminAsync(api);
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(admin, owner.Email);
        var member = await NewMemberAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await JoinAsync(member.Client, club.JoinCode)).StatusCode);
        return (api, owner, member, club);
    }

    private static ClubPlanNotifier NotifierAt(TestApi api, DateTimeOffset now) =>
        new(api.Services.GetRequiredService<IServiceScopeFactory>(), new FixedTime(now), NullLogger<ClubPlanNotifier>.Instance);

    private static async Task<NotificationResponse[]> PlanNoticesAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!.Notifications
            .Where(n => n.Type is NotificationTypes.ClubPlanEnding or NotificationTypes.ClubPlanEnded)
            .ToArray();

    [Fact]
    public async Task ClubPlanNotifier_ShouldWarnOnceAndAnnounceOnceAndOnlyTheOwner_WhenTheDateApproaches()
    {
        var (api, owner, member, club) = await ClubWithPlanAsync();
        await using var _ = api;
        var paidUntil = new DateOnly(2027, 3, 31);
        await SetPlanDirectAsync(api, club.Id, 25, paidUntil);
        DateTimeOffset At(DateOnly day) => new(day.ToDateTime(new TimeOnly(9, 0)), TimeSpan.Zero);

        // Fifteen days out: nothing yet.
        Assert.Equal(0, await NotifierAt(api, At(paidUntil.AddDays(-15))).RunOnceAsync(Ct));
        Assert.Empty(await PlanNoticesAsync(owner.Client));

        // Fourteen days out, and every later run: one warning.
        Assert.Equal(1, await NotifierAt(api, At(paidUntil.AddDays(-14))).RunOnceAsync(Ct));
        Assert.Equal(0, await NotifierAt(api, At(paidUntil.AddDays(-14))).RunOnceAsync(Ct));
        Assert.Equal(0, await NotifierAt(api, At(paidUntil.AddDays(-3))).RunOnceAsync(Ct));
        var warning = Assert.Single(await PlanNoticesAsync(owner.Client));
        Assert.Equal(NotificationTypes.ClubPlanEnding, warning.Type);
        Assert.Equal("2027-03-31", warning.Subject);

        // The last paid day is not yet the end; the day after is.
        Assert.Equal(0, await NotifierAt(api, At(paidUntil)).RunOnceAsync(Ct));
        Assert.Equal(1, await NotifierAt(api, At(paidUntil.AddDays(1))).RunOnceAsync(Ct));
        Assert.Equal(0, await NotifierAt(api, At(paidUntil.AddDays(9))).RunOnceAsync(Ct));
        Assert.Equal([NotificationTypes.ClubPlanEnded, NotificationTypes.ClubPlanEnding], (await PlanNoticesAsync(owner.Client)).Select(n => n.Type).Order());

        // An ordinary member is told nothing, and the club is untouched.
        Assert.Empty(await PlanNoticesAsync(member.Client));
        Assert.Equal(2, (await MyClubOrNullAsync(member.Client))!.Members.Length);

        // Renewing earns a fresh pair of notices for the new date.
        var renewed = paidUntil.AddYears(1);
        await SetPlanDirectAsync(api, club.Id, 25, renewed);
        Assert.Equal(1, await NotifierAt(api, At(renewed.AddDays(-14))).RunOnceAsync(Ct));
        Assert.Equal(3, (await PlanNoticesAsync(owner.Client)).Length);
    }

    [Fact]
    public async Task ClubPlanNotifier_ShouldCatchUp_WhenARunWasMissed()
    {
        var (api, owner, _, club) = await ClubWithPlanAsync();
        await using var _ = api;
        var paidUntil = new DateOnly(2027, 6, 30);
        await SetPlanDirectAsync(api, club.Id, null, paidUntil);

        // The first run happens only after the date passed: the owner hears it ended, once, and no stale warning.
        var now = new DateTimeOffset(2027, 7, 5, 9, 0, 0, TimeSpan.Zero);
        Assert.Equal(1, await NotifierAt(api, now).RunOnceAsync(Ct));
        Assert.Equal(0, await NotifierAt(api, now.AddDays(1)).RunOnceAsync(Ct));
        Assert.Equal(NotificationTypes.ClubPlanEnded, Assert.Single(await PlanNoticesAsync(owner.Client)).Type);
    }

    [Fact]
    public async Task ClubPlanNotifier_ShouldIgnoreClubsWithoutADate_WhenCheckingPlans()
    {
        var (api, owner, _, _) = await ClubWithPlanAsync();
        await using var _ = api;

        Assert.Equal(0, await NotifierAt(api, new DateTimeOffset(2040, 1, 1, 0, 0, 0, TimeSpan.Zero)).RunOnceAsync(Ct));
        Assert.Empty(await PlanNoticesAsync(owner.Client));
    }

    [Theory]
    [InlineData("en", "Your club's plan ends on", "31 March 2027")]
    [InlineData("it", "Il piano del tuo club scade il", "31 marzo 2027")]
    public void NotificationText_ShouldNameTheDateInTheMemberLanguage_WhenAPlanIsEnding(string language, string start, string date)
    {
        using var _ = EmailLanguage.Use(language);

        var sentence = NotificationText.Sentence(new Notification { Type = NotificationTypes.ClubPlanEnding, Subject = "2027-03-31" });

        Assert.Contains(start, sentence);
        Assert.Contains(date, sentence);
        Assert.DoesNotContain("ClubPlan", NotificationText.Sentence(new Notification { Type = NotificationTypes.ClubPlanEnded, Subject = "2027-03-31" }));
    }

}
