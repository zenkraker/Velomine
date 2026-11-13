using System.Net;
using System.Net.Http.Json;
using System.Data.Common;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Rides.TestRideFiles;
using Member = Velomine.Server.Tests.TestMember;

namespace Velomine.Server.Tests.Sharing;

public sealed class SharingTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));


    private static Task<Member> NewMemberAsync(TestApi api) => api.NewMemberAsync();

    private static async Task<AdminClubResponse> CreateClubAsync(TestApi api, Member owner)
    {
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = owner.Email },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    private static async Task JoinAsync(Member member, AdminClubResponse club)
    {
        (await member.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
    }

    private static Task<HttpResponseMessage> ShareAsync(
        Member member,
        string rides,
        string analytics = "none",
        string routes = "none",
        string wellbeing = "none") =>
        member.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = rides, Analytics = analytics, Routes = routes, Wellbeing = wellbeing },
            Ct);

    private static Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file) => TestApi.UploadAndWaitAsync(client, file);

    /// <summary>Counts the reads a request made, so a batching change that adds one per athlete is caught.</summary>
    private sealed class SelectCounter : DbCommandInterceptor
    {
        public int Selects { get; private set; }

        public void Reset() => Selects = 0;

        private static bool IsSelect(DbCommand command) =>
            command.CommandText.TrimStart().StartsWith("SELECT", StringComparison.OrdinalIgnoreCase);

        public override InterceptionResult<DbDataReader> ReaderExecuting(
            DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result)
        {
            if (IsSelect(command)) Selects++;
            return result;
        }

        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(
            DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result,
            CancellationToken cancellationToken = default)
        {
            if (IsSelect(command)) Selects++;
            return ValueTask.FromResult(result);
        }
    }

    [Fact]
    public async Task ListCoachAthletes_ShouldRunAConstantNumberOfQueries_WhenTheRosterGrows()
    {
        var counter = new SelectCounter();
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(services => services.AddSingleton<IInterceptor>(counter));
        });
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var first = await NewMemberAsync(api);
        await JoinAsync(first, club);
        await UploadAndWaitAsync(first.Client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));
        (await ShareAsync(first, "coaches", "coaches")).EnsureSuccessStatusCode();

        await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes", Ct);
        counter.Reset();
        await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes", Ct);
        var one = counter.Selects;

        for (var i = 0; i < 19; i++)
        {
            var more = await NewMemberAsync(api);
            await JoinAsync(more, club);
            (await ShareAsync(more, "coaches", "coaches")).EnsureSuccessStatusCode();
        }

        counter.Reset();
        await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes", Ct);

        Assert.Equal(one, counter.Selects);
    }

    [Fact]
    public async Task ListCoachRides_ShouldUseTheSameCursorRules_WhenPaging()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var start = new DateTime(2026, 10, 3, 8, 0, 0, DateTimeKind.Utc);
        foreach (var day in new[] { 1, 2, 3 })
            await UploadAndWaitAsync(athlete.Client, Fit(new FitSession(start.AddDays(day), 60)));
        (await ShareAsync(athlete, "coaches")).EnsureSuccessStatusCode();

        var page1 = await owner.Client.GetFromJsonAsync<ListRidesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides?limit=2", Ct);
        Assert.Equal([start.AddDays(3), start.AddDays(2)],
            page1!.Rides.Select(r => r.StartTime!.Value.UtcDateTime).ToArray());
        Assert.NotNull(page1.Next);

        var page2 = await owner.Client.GetFromJsonAsync<ListRidesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides?limit=2&cursor={Uri.EscapeDataString(page1.Next)}", Ct);
        Assert.Equal([start.AddDays(1)],
            page2!.Rides.Select(r => r.StartTime!.Value.UtcDateTime).ToArray());
        Assert.Null(page2.Next);

        Assert.Equal(HttpStatusCode.BadRequest, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides?cursor=nonsense", Ct)).StatusCode);
    }

    [Fact]
    public async Task Sharing_ShouldRequireAClubAndStartAtNone_WhenFirstUsed()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.Conflict, (await rider.Client.GetAsync("/api/v1/sharing", Ct)).StatusCode);

        var club = await CreateClubAsync(api, rider);
        var sharing = await rider.Client.GetFromJsonAsync<SharingResponse>("/api/v1/sharing", Ct);
        Assert.Equal(new SharingResponse("none", "none", "none", "none"), sharing);

        Assert.Equal(HttpStatusCode.OK, (await ShareAsync(rider, "coaches", "coaches", "none")).StatusCode);
        var saved = await rider.Client.GetFromJsonAsync<SharingResponse>("/api/v1/sharing", Ct);
        Assert.Equal(new SharingResponse("coaches", "coaches", "none", "none"), saved);

        // Whole-club reading comes with a member-facing club view; until then the choice is refused.
        Assert.Equal(HttpStatusCode.BadRequest, (await ShareAsync(rider, "coaches", "club", "none")).StatusCode);
        // Routes are a map on shared rides, so they cannot stand alone.
        Assert.Equal(HttpStatusCode.BadRequest, (await ShareAsync(rider, "none", "none", "coaches")).StatusCode);
    }

    [Fact]
    public async Task Sharing_ShouldKeepRidesAndTrainingApart_WhenOnlyOneKindIsShared()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        await UploadAndWaitAsync(
            athlete.Client,
            Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));

        (await ShareAsync(athlete, "coaches", "none")).EnsureSuccessStatusCode();
        var ridesOnly = await owner.Client.GetFromJsonAsync<CoachAthleteResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}", Ct);
        Assert.True(ridesOnly!.SharesRides);
        Assert.False(ridesOnly.SharesAnalytics);
        Assert.Equal(1, ridesOnly.Rides);
        Assert.NotNull(ridesOnly.LastRideAt);
        Assert.Null(ridesOnly.Tss7);
        Assert.Null(ridesOnly.Tss42);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/training", Ct)).StatusCode);

        (await ShareAsync(athlete, "none", "coaches")).EnsureSuccessStatusCode();
        var trainingOnly = await owner.Client.GetFromJsonAsync<CoachAthleteResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}", Ct);
        Assert.False(trainingOnly!.SharesRides);
        Assert.True(trainingOnly.SharesAnalytics);
        Assert.Null(trainingOnly.Rides);
        Assert.Null(trainingOnly.DistanceM);
        Assert.Null(trainingOnly.LastRideAt);
        Assert.NotNull(trainingOnly.Tss7);
        Assert.NotNull(trainingOnly.Tss42);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides", Ct)).StatusCode);
    }

    [Fact]
    public async Task Sharing_ShouldKeepEachAthleteApartAndLogTheView_WhenReadingTheRoster()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var ridesOnly = await NewMemberAsync(api);
        var trainingOnly = await NewMemberAsync(api);
        await JoinAsync(ridesOnly, club);
        await JoinAsync(trainingOnly, club);
        await UploadAndWaitAsync(
            ridesOnly.Client,
            Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));
        await UploadAndWaitAsync(
            trainingOnly.Client,
            Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));
        (await ShareAsync(ridesOnly, "coaches", "none")).EnsureSuccessStatusCode();
        (await ShareAsync(trainingOnly, "none", "coaches")).EnsureSuccessStatusCode();

        var roster = await owner.Client.GetFromJsonAsync<CoachAthletesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes", Ct);

        // One rider's choice must not colour the other's numbers.
        var rides = Assert.Single(roster!.Athletes, a => a.UserId == ridesOnly.Id);
        Assert.True(rides.SharesRides);
        Assert.False(rides.SharesAnalytics);
        Assert.NotNull(rides.Rides);
        Assert.Null(rides.Tss7);

        var training = Assert.Single(roster.Athletes, a => a.UserId == trainingOnly.Id);
        Assert.False(training.SharesRides);
        Assert.True(training.SharesAnalytics);
        Assert.Null(training.Rides);
        Assert.NotNull(training.Tss7);

        // The roster shows a snapshot, so it leaves a trace like opening each athlete.
        foreach (var athlete in new[] { ridesOnly, trainingOnly })
        {
            var views = await athlete.Client.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
            Assert.Contains(views!.Views, v => v.What == ViewKinds.Summary && v.ViewerName == "Test Rider");
        }
    }

    [Fact]
    public async Task Sharing_ShouldShowSharedTrainingAndRidesButNoRoute_WhenACoachLooks()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await UploadAndWaitAsync(
            athlete.Client,
            Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 600)));

        // Nothing shared yet: the athlete is not even listed.
        var before = await owner.Client.GetFromJsonAsync<CoachAthletesResponse>($"/api/v1/clubs/{club.Id}/athletes", Ct);
        Assert.Empty(before!.Athletes);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/training", Ct)).StatusCode);

        (await ShareAsync(athlete, "coaches", "coaches", "none")).EnsureSuccessStatusCode();

        var after = await owner.Client.GetFromJsonAsync<CoachAthletesResponse>($"/api/v1/clubs/{club.Id}/athletes", Ct);
        var summary = Assert.Single(after!.Athletes);
        Assert.Equal(athlete.Id, summary.UserId);
        Assert.True(summary.SharesRides);
        Assert.True(summary.SharesAnalytics);
        Assert.False(summary.SharesRoutes);
        Assert.Equal(1, summary.Rides);

        var training = await owner.Client.GetFromJsonAsync<TrainingResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/training?days=30", Ct);
        Assert.Equal(30, training!.DayCount);
        Assert.Equal(1, training.Rides);

        var rides = await owner.Client.GetFromJsonAsync<ListRidesResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides", Ct);
        Assert.Equal(ride.Id, Assert.Single(rides!.Rides).Id);

        var one = await owner.Client.GetFromJsonAsync<RideResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        Assert.Equal(ride.Id, one!.Id);

        var streams = await owner.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);
        Assert.Null(streams!.Latitude);
        Assert.Null(streams.Longitude);
        Assert.NotNull(streams.Power);
        Assert.NotNull(streams.Time);

        var views = await athlete.Client.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
        Assert.Contains(views!.Views, v => v.What == ViewKinds.Training && v.ViewerName == "Test Rider");
        Assert.Contains(views.Views, v => v.What == ViewKinds.Ride);
    }

    [Fact]
    public async Task CoachRides_ShouldHideTrainingLoad_WhenAnalyticsIsNotShared()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        (await athlete.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", 250, null, 1990, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        var ride = await UploadAndWaitAsync(athlete.Client, Fit(new FitSession(Start, 600)));
        (await ShareAsync(athlete, "coaches", "none")).EnsureSuccessStatusCode();

        var list = await owner.Client.GetFromJsonAsync<ListRidesResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides", Ct);
        var listed = Assert.Single(list!.Rides);
        Assert.Null(listed.IntensityFactor);
        Assert.Null(listed.Tss);
        Assert.Null(listed.Trimp);

        var hidden = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        Assert.Null(hidden!.IntensityFactor);
        Assert.Null(hidden.Tss);
        Assert.Null(hidden.Trimp);
        Assert.Null(hidden.HeartRateZones);
        Assert.Null(hidden.PowerZones);

        (await ShareAsync(athlete, "coaches", "coaches")).EnsureSuccessStatusCode();
        var shown = await owner.Client.GetFromJsonAsync<RideResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}", Ct);
        Assert.NotNull(shown!.IntensityFactor);
        Assert.NotNull(shown.Tss);
        Assert.NotNull(shown.Trimp);
        // The ride is 600 s at a steady 150 bpm and 200 W: 599 counted intervals. Against a maximum of 183 (Tanaka for
        // 1990) that is 82 %, heart-rate zone 4 (index 3); against a 250 W FTP it is 80 %, power zone 3 (index 2,
        // because 80 % is above the 75 % bound).
        var heartRateZones = shown.HeartRateZones!;
        Assert.Equal(599, heartRateZones[3].Seconds);
        Assert.All(heartRateZones.Where((_, i) => i != 3), zone => Assert.Equal(0, zone.Seconds));
        var powerZones = shown.PowerZones!;
        Assert.Equal(599, powerZones[2].Seconds);
        Assert.All(powerZones.Where((_, i) => i != 2), zone => Assert.Equal(0, zone.Seconds));
    }

    [Fact]
    public async Task Sharing_ShouldShowTheRoute_WhenRoutesAreShared()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        var ride = await UploadAndWaitAsync(athlete.Client, Fit(new FitSession(Start, 60)));
        (await ShareAsync(athlete, "coaches")).EnsureSuccessStatusCode();

        var hidden = await owner.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);
        Assert.Null(hidden!.Latitude);

        (await ShareAsync(athlete, "coaches", "none", "coaches")).EnsureSuccessStatusCode();
        var shown = await owner.Client.GetFromJsonAsync<RideStreamsResponse>($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}/streams", Ct);
        Assert.NotNull(shown!.Latitude);
        Assert.NotNull(shown.Longitude);
    }

    [Fact]
    public async Task Sharing_ShouldRefuseTheLook_WhenTheViewerIsNotACoachOfThatClub()
    {
        await using var api = await StartAsync();
        var ownerA = await NewMemberAsync(api);
        var clubA = await CreateClubAsync(api, ownerA);
        var ownerB = await NewMemberAsync(api);
        _ = await CreateClubAsync(api, ownerB);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, clubA);
        await ShareAsync(athlete, "coaches", "coaches", "coaches");

        // The coach of another club sees nothing.
        Assert.Equal(HttpStatusCode.NotFound, (await ownerB.Client.GetAsync($"/api/v1/clubs/{clubA.Id}/athletes/{athlete.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await ownerB.Client.GetAsync($"/api/v1/clubs/{clubA.Id}/athletes/{athlete.Id}/training", Ct)).StatusCode);

        // A plain rider of the same club is not a coach.
        var other = await NewMemberAsync(api);
        await JoinAsync(other, clubA);
        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.GetAsync($"/api/v1/clubs/{clubA.Id}/athletes/{athlete.Id}", Ct)).StatusCode);

        // The admin does not get ride data either.
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.GetAsync($"/api/v1/clubs/{clubA.Id}/athletes/{athlete.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task Sharing_ShouldWithdrawTheData_WhenTheLookIsRevokedOrTheClubIsLeft()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        (await ShareAsync(athlete, "coaches", "coaches")).EnsureSuccessStatusCode();

        Assert.Equal(HttpStatusCode.OK, (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}", Ct)).StatusCode);

        (await ShareAsync(athlete, "none", "none")).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}", Ct)).StatusCode);

        (await ShareAsync(athlete, "coaches", "coaches", "coaches")).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NoContent, (await athlete.Client.PostAsync("/api/v1/club/leave", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}", Ct)).StatusCode);

        await JoinAsync(athlete, club);
        var sharing = await athlete.Client.GetFromJsonAsync<SharingResponse>("/api/v1/sharing", Ct);
        Assert.Equal(new SharingResponse("none", "none", "none", "none"), sharing);
    }

    [Fact]
    public async Task GetCoachRideLaps_ShouldReturnTheAthletesLaps_WhenRidesAreShared()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var club = await CreateClubAsync(api, owner);
        var athlete = await NewMemberAsync(api);
        await JoinAsync(athlete, club);
        (await ShareAsync(athlete, "coaches")).EnsureSuccessStatusCode();
        var ride = await UploadAndWaitAsync(
            athlete.Client,
            Fit(new FitSession(Start, 120, LapSeconds: [60, 60])));

        var laps = await owner.Client.GetFromJsonAsync<RideLapsResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}/laps", Ct);
        Assert.Equal(2, laps!.Laps.Length);

        (await ShareAsync(athlete, "none")).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.NotFound, (await owner.Client.GetAsync(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/rides/{ride.Id}/laps", Ct)).StatusCode);
    }
}
