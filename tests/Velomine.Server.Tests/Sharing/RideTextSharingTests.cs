using System.Net;
using System.Net.Http.Json;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Sharing;

/// <summary>A ride's title and description, and who looked at a ride, across members and clubs.</summary>
public sealed class RideTextSharingTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<TestMember> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        var id = (await (await api.RegisterAsync(email, name: name)).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;
        return new TestMember(email, id, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task JoinAsync(TestMember member, AdminClubResponse club) =>
        (await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();

    private static Task<HttpResponseMessage> ShareRidesAsync(TestMember member, string rides) =>
        member.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = rides, Analytics = "none", Routes = "none", Wellbeing = "none" },
            Ct);

    /// <summary>Uploads a ride and gives it a title and a description.</summary>
    private static async Task<RideResponse> NamedRideAsync(TestMember member, DateTime start, string title, string description)
    {
        var ride = await TestApi.UploadAndWaitAsync(member.Client, Fit(new FitSession(start, 120)));
        var named = await member.Client.PutAsJsonAsync(
            $"/api/v1/rides/{ride.Id}/details",
            new SetRideDetailsRequest { Title = title, Description = description, Version = ride.Version },
            Ct);
        named.EnsureSuccessStatusCode();
        return (await named.Content.ReadFromJsonAsync<RideResponse>(Ct))!;
    }

    private static string Rides(AdminClubResponse club, TestMember athlete) => $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides";

    [Fact]
    public async Task CoachRides_ShouldShowTitleAndDescription_WhenTheCoachHasTheRidesGrant()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await NamedRideAsync(athlete, Start, "Dawn patrol", "Cold start, warm finish");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();

        var list = await coach.Client.GetFromJsonAsync<ListRidesResponse>(Rides(club, athlete), Ct);
        var one = await coach.Client.GetFromJsonAsync<RideResponse>($"{Rides(club, athlete)}/{ride.Id}", Ct);

        var listed = Assert.Single(list!.Rides);
        Assert.Equal("Dawn patrol", listed.Title);
        Assert.Equal("Cold start, warm finish", listed.Description);
        Assert.Equal("Dawn patrol", one!.Title);
        Assert.Equal("Cold start, warm finish", one.Description);
    }

    [Fact]
    public async Task CoachRides_ShouldShowNothing_WhenTheMemberHasNotSharedRides()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await NamedRideAsync(athlete, Start, "Private words", "Nobody reads these");

        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync(Rides(club, athlete), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync($"{Rides(club, athlete)}/{ride.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachRides_ShouldNotShowTitleOrDescription_WhenTheRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await NamedRideAsync(athlete, Start, "Club ride title", "Club ride words");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();
        var strangerCoach = await NewMemberAsync(api);
        var otherClub = await TestClubs.CreateAsync(api, strangerCoach);

        // Asking through the other club, or through the athlete's club, is a 404 either way.
        var throughOwnClub = await strangerCoach.Client.GetAsync(Rides(club, athlete), Ct);
        var throughOtherClub = await strangerCoach.Client.GetAsync(Rides(otherClub, athlete), Ct);
        var oneThroughOtherClub = await strangerCoach.Client.GetAsync($"{Rides(otherClub, athlete)}/{ride.Id}", Ct);

        foreach (var response in new[] { throughOwnClub, throughOtherClub, oneThroughOtherClub })
        {
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
            var body = await response.Content.ReadAsStringAsync(Ct);
            Assert.DoesNotContain("Club ride", body);
        }
    }

    [Fact]
    public async Task CoachRides_ShouldNotShowTitleOrDescription_WhenTheViewerIsAClubMemberWhoIsNotACoach()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        var teammate = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        await JoinAsync(teammate, club);
        await NamedRideAsync(athlete, Start, "Club ride title", "Club ride words");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();

        var response = await teammate.Client.GetAsync(Rides(club, athlete), Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // --- Who looked

    private static async Task<ShareViewResponse[]> ViewsOfAsync(TestMember owner, Guid rideId) =>
        (await owner.Client.GetFromJsonAsync<ShareViewsResponse>($"/api/v1/sharing/views?rideId={rideId}", Ct))!.Views;

    [Fact]
    public async Task ShareViews_ShouldListWhoLookedAtTheRide_WhenACoachOpenedIt()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api, "Marco Coach");
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var watched = await NamedRideAsync(athlete, Start, "Watched", "");
        var unwatched = await NamedRideAsync(athlete, Start.AddDays(1), "Unwatched", "");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();
        Assert.Empty(await ViewsOfAsync(athlete, watched.Id));

        (await coach.Client.GetAsync($"{Rides(club, athlete)}/{watched.Id}", Ct)).EnsureSuccessStatusCode();
        // The samples and laps of the same ride are fetched in the same moment; that is one look.
        (await coach.Client.GetAsync($"{Rides(club, athlete)}/{watched.Id}/streams", Ct)).EnsureSuccessStatusCode();
        (await coach.Client.GetAsync($"{Rides(club, athlete)}/{watched.Id}/laps", Ct)).EnsureSuccessStatusCode();

        var views = await ViewsOfAsync(athlete, watched.Id);
        var view = Assert.Single(views);
        Assert.Equal("Marco Coach", view.ViewerName);
        Assert.Empty(await ViewsOfAsync(athlete, unwatched.Id));
    }

    [Fact]
    public async Task ShareViews_ShouldNotShowLooksAtOtherRides_WhenListingOneRide()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var first = await NamedRideAsync(athlete, Start, "First", "");
        var second = await NamedRideAsync(athlete, Start.AddDays(1), "Second", "");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();

        await coach.Client.GetAsync($"{Rides(club, athlete)}/{first.Id}", Ct);

        Assert.Single(await ViewsOfAsync(athlete, first.Id));
        Assert.Empty(await ViewsOfAsync(athlete, second.Id));
        // The list a coach opens is a look at the list, not at one ride.
        await coach.Client.GetAsync(Rides(club, athlete), Ct);
        Assert.Empty(await ViewsOfAsync(athlete, second.Id));
    }

    [Fact]
    public async Task ShareViews_ShouldReadOnlyTheCallersOwnLog_WhenAskingAboutSomeoneElsesRide()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        var teammate = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        await JoinAsync(teammate, club);
        var ride = await NamedRideAsync(athlete, Start, "Watched", "");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();
        await coach.Client.GetAsync($"{Rides(club, athlete)}/{ride.Id}", Ct);

        // Neither the viewer nor another member of the club can read the athlete's log for that ride.
        Assert.Empty(await ViewsOfAsync(teammate, ride.Id));
        Assert.Empty(await ViewsOfAsync(coach, ride.Id));
        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await api.CreateClient().GetAsync($"/api/v1/sharing/views?rideId={ride.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task ShareViews_ShouldKeepTheLogButDropTheRide_WhenTheRideIsDeleted()
    {
        await using var api = await StartAsync();
        var coach = await NewMemberAsync(api);
        var club = await TestClubs.CreateAsync(api, coach);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await NamedRideAsync(athlete, Start, "Watched", "");
        (await ShareRidesAsync(athlete, "coaches")).EnsureSuccessStatusCode();
        await coach.Client.GetAsync($"{Rides(club, athlete)}/{ride.Id}", Ct);

        (await athlete.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).EnsureSuccessStatusCode();

        Assert.Empty(await ViewsOfAsync(athlete, ride.Id));
        var log = await athlete.Client.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
        Assert.Single(log!.Views);
    }
}
