using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Sharing;

/// <summary>
/// The coach's read of a rider's auto plan: a rides grant for the coaches audience and nothing else, the illness reason
/// only with the wellbeing grant, no score, and every look written down for the rider to read.
/// </summary>
public sealed class CoachPlanTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Tuesday 24 November 2026 at midday UTC, in a week that starts on Monday.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 12, 0, 0, TimeSpan.Zero);

    private static readonly DateOnly Monday = new(2026, 11, 23);
    private static readonly DateOnly Today = Monday.AddDays(1);
    private static readonly DateOnly Thursday = Monday.AddDays(3);
    private static readonly DateOnly Friday = Monday.AddDays(4);
    private static readonly DateOnly Saturday = Monday.AddDays(5);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FakeTime { Now = Now }));
    });

    private static async Task<TestMember> NewRiderAsync(TestApi api, string name = "Test Rider")
    {
        var member = await api.NewMemberAsync(name);
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest(name, null, null, null, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        return member;
    }

    private static async Task ShareRidesAsync(TestMember rider) =>
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest
            {
                Rides = Audiences.Coaches, Analytics = "none", Routes = "none", Wellbeing = "none",
            }, Ct)).EnsureSuccessStatusCode();

    /// <summary>
    /// This week as the planner would leave it on Tuesday: today ridden, Thursday planned, Friday skipped because tired,
    /// Saturday skipped because ill.
    /// </summary>
    private static async Task PlanWeekAsync(TestApi api, Guid userId, bool on = true)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.TrainingPlans.Add(new TrainingPlan
        {
            UserId = userId,
            Goal = TrainingGoals.Fitter,
            Days = [1, 3, 4, 5],
            HoursPerWeek = 6,
            LongRideDay = null,
            LastPlannedFor = Today,
            IsOn = on,
            UpdatedAt = Now,
        });

        var ride = new Ride
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Status = RideStatus.Ready,
            StartTime = new DateTimeOffset(Today.ToDateTime(new TimeOnly(9, 0)), TimeSpan.Zero),
            UtcOffsetMinutes = 0,
            MovingS = 3900,
            Tss = 100,
        };
        db.Rides.Add(ride);

        void Session(DateOnly date, int minutes, string state, Guid? rideId = null, string? reason = null) =>
            db.TrainingSessions.Add(new TrainingSession
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                LocalDate = date,
                Recipe = "R02",
                Minutes = minutes,
                BlockPercents = [70],
                State = state,
                SkipReason = reason,
                RideId = rideId,
                CreatedAt = Now,
            });

        Session(Today, 75, TrainingSessionStates.Done, ride.Id);
        Session(Thursday, 90, TrainingSessionStates.Planned);
        Session(Friday, 60, TrainingSessionStates.Skipped, reason: TrainingSkipReasons.Tired);
        Session(Saturday, 60, TrainingSessionStates.Skipped, reason: TrainingSkipReasons.Ill);
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>A club with its owner, a rider in it and the path to the rider's plan.</summary>
    private static async Task<(AdminClubResponse Club, TestMember Owner, TestMember Rider)> ClubAsync(TestApi api)
    {
        var owner = await NewRiderAsync(api, "Coach Rina");
        var club = await TestClubs.CreateAsync(api, owner);
        var rider = await NewRiderAsync(api, "Rider Luca");
        await TestClubs.JoinAsync(rider, club);
        return (club, owner, rider);
    }

    private static string PlanPath(AdminClubResponse club, TestMember rider) =>
        $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/plan";

    [Fact]
    public async Task CoachPlan_ShouldShowTheGoalAndTheWeek_WhenRidesAreSharedWithCoaches()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        var plan = await coach.Client.GetFromJsonAsync<CoachPlanResponse>(PlanPath(club, rider), Ct);

        Assert.NotNull(plan);
        Assert.Equal(TrainingGoals.Fitter, plan.Goal);
        Assert.Equal(6, plan.HoursPerWeek);
        Assert.Equal(Monday, plan.Start);
        Assert.Equal(Monday.AddDays(6), plan.End);
        Assert.Equal([Today, Thursday, Friday, Saturday], plan.Sessions.Select(s => s.LocalDate));

        // Both languages, so the app reads the pair it shows (TrainingNames.md).
        var done = plan.Sessions[0];
        Assert.Equal("done", done.State);
        Assert.Equal("Easy ride", done.EnglishName);
        Assert.Equal("Giro tranquillo", done.ItalianName);
        Assert.Equal(75, done.Minutes);
        Assert.Equal(65, done.RiddenMinutes);
        Assert.Null(plan.Sessions[1].RiddenMinutes);
        Assert.Equal(TrainingSkipReasons.Tired, plan.Sessions[2].SkipReason);
    }

    [Fact]
    public async Task CoachPlan_ShouldRecordTheLookAsAPlan_WhenACoachReadsIt()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        Assert.Equal(HttpStatusCode.OK, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);

        var views = await rider.Client.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
        Assert.Contains(views!.Views, v => v.What == ViewKinds.Plan && v.ViewerName == "Coach Rina");
    }

    [Fact]
    public async Task CoachPlan_ShouldHideTheIllnessReason_WhenWellbeingIsNotShared()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        var plan = await coach.Client.GetFromJsonAsync<CoachPlanResponse>(PlanPath(club, rider), Ct);

        // "Ill or injured" is health data: without its grant the coach reads "Skipped" and nothing more.
        var ill = plan!.Sessions.Single(s => s.LocalDate == Saturday);
        Assert.Equal(TrainingSessionStates.Skipped, ill.State);
        Assert.Null(ill.SkipReason);
        // The other reasons follow the rides grant.
        Assert.Equal(TrainingSkipReasons.Tired, plan.Sessions.Single(s => s.LocalDate == Friday).SkipReason);
    }

    [Fact]
    public async Task CoachPlan_ShouldShowTheIllnessReason_WhenWellbeingIsShared()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        (await rider.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest
            {
                Rides = Audiences.Coaches, Analytics = "none", Routes = "none", Wellbeing = Audiences.Coaches,
            }, Ct)).EnsureSuccessStatusCode();

        var plan = await coach.Client.GetFromJsonAsync<CoachPlanResponse>(PlanPath(club, rider), Ct);

        Assert.Equal(TrainingSkipReasons.Ill,
            plan!.Sessions.Single(s => s.LocalDate == Saturday).SkipReason);
    }

    [Fact]
    public async Task CoachPlan_ShouldCarryNoScoreAndNoCheckIn_WhenASessionIsDone()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        var raw = await coach.Client.GetStringAsync(PlanPath(club, rider), Ct);

        // The 0–100 session score and every check-in answer stay with the rider; the card cannot leak what the
        // endpoint never reads.
        Assert.DoesNotContain("score", raw, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("checkIn", raw, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("readiness", raw, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("easy:", raw, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CoachPlan_ShouldGiveNothing_WhenOnlyTheClubAudienceIsGranted()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            db.ShareGrants.Add(new ShareGrant
            {
                Id = Guid.NewGuid(),
                MemberId = rider.Id,
                ClubId = club.Id,
                DataType = DataTypes.Rides,
                Audience = Audiences.Club,
                UpdatedAt = Now,
            });
            await db.SaveChangesAsync(Ct);
        }

        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachPlan_ShouldBeGone_WhenTheGrantIsWithdrawn()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);
        Assert.Equal(HttpStatusCode.OK, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);

        (await rider.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest
            {
                Rides = "none", Analytics = "none", Routes = "none", Wellbeing = "none",
            }, Ct)).EnsureSuccessStatusCode();

        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachPlan_ShouldGiveNothing_WhenTheViewerIsAPlainMemberOfTheClub()
    {
        await using var api = await StartAsync();
        var (club, _, rider) = await ClubAsync(api);
        var member = await NewRiderAsync(api, "Just A Member");
        await TestClubs.JoinAsync(member, club);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        Assert.Equal(HttpStatusCode.NotFound, (await member.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachPlan_ShouldGiveNothing_WhenTheClubOwnerHasNoGrant()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        // Nothing shared: the club's role gives its owner nothing of the rider's plan.
        var sharing = await rider.Client.GetFromJsonAsync<SharingResponse>("/api/v1/sharing", Ct);
        Assert.Equal("none", sharing!.Rides);

        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachPlan_ShouldGiveNothing_WhenAutoTrainingIsOff()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id, on: false);
        await ShareRidesAsync(rider);

        Assert.Equal(HttpStatusCode.NotFound, (await coach.Client.GetAsync(PlanPath(club, rider), Ct)).StatusCode);
    }

    [Fact]
    public async Task CoachPlan_ShouldStayTheRiders_WhenTheCoachSavesAPlanOfTheirOwn()
    {
        await using var api = await StartAsync();
        var (club, coach, rider) = await ClubAsync(api);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        // No write endpoint takes an athlete: the coach's save is their own plan and leaves the rider's alone.
        (await coach.Client.PutAsJsonAsync("/api/v1/training/plan",
            new SaveTrainingPlanRequest(
                TrainingGoals.Faster, ["monday", "wednesday"], 4, null, true, 190, 1985, null), Ct))
            .EnsureSuccessStatusCode();

        var plan = await coach.Client.GetFromJsonAsync<CoachPlanResponse>(PlanPath(club, rider), Ct);
        Assert.Equal(TrainingGoals.Fitter, plan!.Goal);
        Assert.Equal(6, plan.HoursPerWeek);
        Assert.Equal(4, plan.Sessions.Length);
    }

    [Fact]
    public async Task ClubData_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var first = await NewRiderAsync(api, "First Owner");
        var firstClub = await TestClubs.CreateAsync(api, first);
        var rider = await NewRiderAsync(api, "Rider Luca");
        await TestClubs.JoinAsync(rider, firstClub);
        await PlanWeekAsync(api, rider.Id);
        await ShareRidesAsync(rider);

        // The other club's owner knows both ids; neither club is his.
        var second = await NewRiderAsync(api, "Second Owner");
        await TestClubs.CreateAsync(api, second);
        var path = PlanPath(firstClub, rider);
        Assert.Equal(HttpStatusCode.NotFound, (await second.Client.GetAsync(path, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await second.Client.GetAsync($"/api/v1/clubs/{firstClub.Id}/athletes/{rider.Id}", Ct)).StatusCode);

        // The rider's own club still reads it, so the answer is about the viewer and not a broken endpoint.
        Assert.Equal(HttpStatusCode.OK, (await first.Client.GetAsync(path, Ct)).StatusCode);
    }
}
