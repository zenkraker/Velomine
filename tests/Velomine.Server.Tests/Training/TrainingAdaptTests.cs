using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Training;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// Today adapts, and the rider can move or skip a session: a check-in, its readiness or a form that stayed low makes a
/// hard day easy and moves the hard work when the week can hold it; the rider can do the same by hand, move a session to
/// another day, or skip it. Every change says why, once, in a notification the owner alone reads.
/// </summary>
public sealed class TrainingAdaptTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Tuesday 24 November 2026 at midday UTC, in a week that starts on Monday.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 12, 0, 0, TimeSpan.Zero);

    private static readonly DateOnly Monday = new(2026, 11, 23);
    private static readonly DateOnly Tuesday = Monday.AddDays(1);
    private static readonly DateOnly Wednesday = Monday.AddDays(2);
    private static readonly DateOnly Thursday = Monday.AddDays(3);
    private static readonly DateOnly Friday = Monday.AddDays(4);
    private static readonly DateOnly Saturday = Monday.AddDays(5);
    private static readonly DateOnly Sunday = Monday.AddDays(6);

    private Task<TestApi> StartAsync(DateTimeOffset? now = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FakeTime { Now = now ?? Now }));
        });

    private static async Task<TestMember> NewMemberAsync(TestApi api, string name = "Rider")
    {
        var member = await api.NewMemberAsync(name);
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest(name, null, null, null, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        return member;
    }

    /// <summary>A rider with a plan that is on and the sessions the test needs; the week was written for today.</summary>
    private static async Task<TestMember> RiderAsync(TestApi api, params (DateOnly Date, string Recipe, int Minutes)[] sessions)
    {
        var member = await NewMemberAsync(api);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.TrainingPlans.Add(new TrainingPlan
        {
            UserId = member.Id,
            Goal = TrainingGoals.Fitter,
            Days = [(int)DayOfWeek.Tuesday, (int)DayOfWeek.Thursday, (int)DayOfWeek.Sunday],
            HoursPerWeek = 6,
            IsOn = true,
            LastPlannedFor = Tuesday,
            UpdatedAt = Now,
        });
        foreach (var (date, recipe, minutes) in sessions)
            db.TrainingSessions.Add(new TrainingSession
            {
                Id = Guid.CreateVersion7(),
                UserId = member.Id,
                LocalDate = date,
                Recipe = recipe,
                Minutes = minutes,
                BlockPercents = SessionPlan.Percents(SessionPlan.For(Recipes.ByCode(recipe), minutes).Blocks),
                State = TrainingSessionStates.Planned,
                CreatedAt = Now,
            });
        await db.SaveChangesAsync(Ct);
        return member;
    }

    /// <summary>Weeks of steady riding, so the rider is past the gentle base block and has a hard day to adapt.</summary>
    private static async Task WithRidingHistoryAsync(TestApi api, Guid userId, int weeks = 5, double tss = 100)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        for (var week = 1; week <= weeks; week++)
            for (var day = 0; day < 5; day++)
                db.Rides.Add(new Ride
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Status = RideStatus.Ready,
                    StartTime = new DateTimeOffset(
                        Monday.AddDays(-7 * week + day).ToDateTime(new TimeOnly(7, 0)), TimeSpan.Zero),
                    UtcOffsetMinutes = 0,
                    MovingS = 3600,
                    Tss = tss,
                });
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>A ride of the load the test needs on one day, read as ready so the readiness and form see it.</summary>
    private static async Task AddRideAsync(TestApi api, Guid userId, DateOnly date, double tss)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Status = RideStatus.Ready,
            StartTime = new DateTimeOffset(date.ToDateTime(new TimeOnly(6, 0)), TimeSpan.Zero),
            UtcOffsetMinutes = 0,
            MovingS = 3600,
            Tss = tss,
        });
        await db.SaveChangesAsync(Ct);
    }

    private static async Task ConsentAsync(TestMember member) =>
        (await member.Client.PostAsJsonAsync("/api/v1/wellbeing/consent", new WellbeingConsentRequest(true), Ct))
        .EnsureSuccessStatusCode();

    private static Task<HttpResponseMessage> CheckInAsync(
        TestMember member, int fatigue, int soreness, int? sleep, int mood = 4, int stress = 2, int motivation = 4) =>
        member.Client.PutAsJsonAsync("/api/v1/wellbeing/check-ins/today",
            new SaveCheckInRequest
            {
                Fatigue = fatigue,
                Soreness = soreness,
                Mood = mood,
                Stress = stress,
                Motivation = motivation,
                Sleep = sleep,
            }, Ct);

    private static TrainingPlanSweeper Sweeper(TestApi api) => new(
        api.Services.GetRequiredService<IServiceScopeFactory>(),
        Options.Create(new TrainingOptions()),
        NullLogger<TrainingPlanSweeper>.Instance);

    private static async Task<List<TrainingSession>> SessionsAsync(TestApi api, Guid userId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == userId && s.LocalDate >= Monday && s.LocalDate <= Sunday)
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(Ct);
    }

    private static async Task<TrainingWeekSession> TodayAsync(TestMember member)
    {
        var week = await WeekAsync(member);
        return Assert.Single(week.Sessions, s => s.LocalDate == Tuesday);
    }

    private static async Task<TrainingWeek> WeekAsync(TestMember member) =>
        Assert.Single((await member.Client.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!.Weeks);

    private static async Task<NotificationResponse[]> NotificationsAsync(TestMember member) =>
        (await member.Client.GetFromJsonAsync<ListNotificationsResponse>("/api/v1/notifications", Ct))!.Notifications;

    [Fact]
    public async Task SaveCheckIn_ShouldMakeTodaysHardSessionEndurance_WhenSleepIsTheWorstAnswer()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Sunday, "R03", 180));
        await ConsentAsync(member);

        (await CheckInAsync(member, fatigue: 2, soreness: 2, sleep: 1)).EnsureSuccessStatusCode();

        // R02 in place of the hard session, at the same length, with the reason kept for the line the rider reads.
        var today = await TodayAsync(member);
        Assert.Equal(TrainingSessionStates.Easy, today.State);
        Assert.Equal(SessionAdaptation.EasyRecipe, today.Recipe);
        Assert.Equal(60, today.Minutes);
        Assert.Equal(TrainingEasyReasons.SleptPoorly, today.EasyReason);

        // The replaced hard session moved to the next free day that keeps the hard days apart: Thursday, the rider's
        // other riding day, two days from Tuesday and three from Sunday's long ride.
        var week = await WeekAsync(member);
        Assert.Equal(Thursday, today.EasyMovedTo);
        var moved = Assert.Single(week.Sessions, s => s.LocalDate == Thursday);
        Assert.Equal(TrainingSessionStates.Planned, moved.State);
        Assert.True(Recipes.ByCode(moved.Recipe).IsQuality);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldAnnounceTheEasyDay_WhenItChangesToday()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);

        (await CheckInAsync(member, fatigue: 5, soreness: 2, sleep: 4)).EnsureSuccessStatusCode();

        var notice = Assert.Single(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingEasy);
        Assert.NotNull(notice.Notice);
        Assert.Equal(TrainingEasyReasons.Tired, notice.Notice!.EasyReason);
        Assert.Equal(TrainingSessionStates.Easy, notice.Notice.State);
        Assert.Equal(TrainingEasyReasons.Tired, (await TodayAsync(member)).EasyReason);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldKeepTheLongRideLong_WhenItIsMadeEasy()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R03", 180));
        await ConsentAsync(member);

        (await CheckInAsync(member, fatigue: 2, soreness: 5, sleep: 3)).EnsureSuccessStatusCode();

        var today = await TodayAsync(member);
        Assert.Equal(SessionAdaptation.EasyRecipe, today.Recipe);
        // A long ride stays as long as it was, only easier; nothing moves, because the week has no free day left after it.
        Assert.Equal(180, today.Minutes);
        Assert.Equal(TrainingEasyReasons.Sore, today.EasyReason);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldMakeTodayEasy_WhenTheReadinessIsInTheRestBand()
    {
        // One very heavy ride leaves the form far below zero, so the readiness of the day is in F2's rest band even
        // though every answer of the check-in is an ordinary one.
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);
        await AddRideAsync(api, member.Id, Tuesday, tss: 800);

        (await CheckInAsync(member, fatigue: 3, soreness: 3, sleep: 3)).EnsureSuccessStatusCode();

        var today = await TodayAsync(member);
        Assert.Equal(TrainingSessionStates.Easy, today.State);
        Assert.Equal(TrainingEasyReasons.FormLow, today.EasyReason);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldLeaveTheSession_WhenTheAnswersAreSound()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);

        (await CheckInAsync(member, fatigue: 3, soreness: 2, sleep: 4)).EnsureSuccessStatusCode();

        var today = await TodayAsync(member);
        Assert.Equal(TrainingSessionStates.Planned, today.State);
        Assert.Equal("R05", today.Recipe);
        Assert.Null(today.EasyReason);
        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingEasy);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldChangeNothing_WhenTheRiderTurnedAutoTrainingOff()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var plan = await db.TrainingPlans.FirstAsync(p => p.UserId == member.Id, Ct);
            plan.IsOn = false;
            await db.SaveChangesAsync(Ct);
        }

        (await CheckInAsync(member, fatigue: 2, soreness: 2, sleep: 1)).EnsureSuccessStatusCode();

        await using var read = api.Services.CreateAsyncScope();
        var sessions = await read.ServiceProvider.GetRequiredService<VelomineDbContext>().TrainingSessions
            .AsNoTracking().Where(s => s.UserId == member.Id).ToListAsync(Ct);
        Assert.Equal(TrainingSessionStates.Planned, Assert.Single(sessions).State);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldMakeTheNextHardDayEasy_WhenTheFormIsBelowTheFloorAndThereIsNoCheckIn()
    {
        // Weeks of riding, then one very heavy day: L2's form is below −30, and with no check-in to explain it the night
        // makes the next hard day an easy one.
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        // A thousand of load a week is the rider's normal, so the week's cap holds a heavy day without shrinking it.
        await WithRidingHistoryAsync(api, member.Id, tss: 200);
        await AddRideAsync(api, member.Id, Tuesday, tss: 400);
        (await member.Client.PutAsJsonAsync("/api/v1/training/plan",
            new SaveTrainingPlanRequest(TrainingGoals.Fitter, ["tuesday", "thursday", "sunday"], 6, null, false, null, 1988, null),
            Ct)).EnsureSuccessStatusCode();

        await Sweeper(api).RunOnceAsync(Ct);

        var sessions = await SessionsAsync(api, member.Id);
        var easy = Assert.Single(sessions, s => s.EasyReason == TrainingEasyReasons.FormLow);
        Assert.Equal(TrainingSessionStates.Easy, easy.State);
        Assert.Equal(SessionAdaptation.EasyRecipe, easy.Recipe);
        Assert.True(Recipes.ByCode(easy.OriginalRecipe!).IsQuality);
        // The hard work moved to a free day rather than being lost, or went when the week had no room for it.
        if (easy.EasyMovedTo is { } movedTo)
            Assert.Contains(sessions, s => s.LocalDate == movedTo && Recipes.ByCode(s.Recipe).IsQuality);
        Assert.Contains(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingEasy);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldLeaveTheHardDay_WhenTheFormIsAboveTheFloor()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await WithRidingHistoryAsync(api, member.Id);
        (await member.Client.PutAsJsonAsync("/api/v1/training/plan",
            new SaveTrainingPlanRequest(TrainingGoals.Fitter, ["tuesday", "thursday", "sunday"], 6, null, false, null, 1988, null),
            Ct)).EnsureSuccessStatusCode();

        await Sweeper(api).RunOnceAsync(Ct);

        Assert.All(await SessionsAsync(api, member.Id), s => Assert.Null(s.EasyReason));
    }

    [Fact]
    public async Task MakeSessionEasy_ShouldMakeTodaysSessionEasy_WhenTheRiderAsks()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Thursday, "R06", 60));
        var today = await TodayAsync(member);

        var answer = await member.Client.PostAsync($"/api/v1/training/sessions/{today.Id}/easy", null, Ct);

        Assert.Equal(HttpStatusCode.OK, answer.StatusCode);
        var week = (await answer.Content.ReadFromJsonAsync<TrainingWeeksResponse>(Ct))!;
        var changed = Assert.Single(week.Weeks[0].Sessions, s => s.LocalDate == Tuesday);
        Assert.Equal(TrainingSessionStates.Easy, changed.State);
        Assert.Equal(SessionAdaptation.EasyRecipe, changed.Recipe);
        Assert.Equal(TrainingEasyReasons.Asked, changed.EasyReason);
        // "Make today easy" is today's session only: nothing else in the week moved.
        Assert.Equal(2, week.Weeks[0].Sessions.Length);
        Assert.DoesNotContain(week.Weeks[0].Sessions, s => s.LocalDate != Tuesday && s.LocalDate != Thursday);
        // The change says why in the inbox too, and the copy the change would have moved is not there.
        Assert.Equal(TrainingEasyReasons.Asked, Assert.Single(await NotificationsAsync(member),
            n => n.Type == NotificationTypes.TrainingEasy).Notice!.EasyReason);
        Assert.Null(changed.EasyMovedTo);
    }

    [Fact]
    public async Task BackToTrainingPlan_ShouldRestoreTheHardSession_WhenItIsTheSameDay()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        var today = await TodayAsync(member);
        (await member.Client.PostAsync($"/api/v1/training/sessions/{today.Id}/easy", null, Ct)).EnsureSuccessStatusCode();

        var answer = await member.Client.DeleteAsync($"/api/v1/training/sessions/{today.Id}/easy", Ct);

        Assert.Equal(HttpStatusCode.OK, answer.StatusCode);
        var restored = Assert.Single((await WeekAsync(member)).Sessions);
        Assert.Equal("R05", restored.Recipe);
        Assert.Equal(TrainingSessionStates.Planned, restored.State);
        Assert.Null(restored.EasyReason);
        // The inbox no longer says today is easy, because it is not.
        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingEasy);
    }

    [Fact]
    public async Task BackToTrainingPlan_ShouldBringTheMovedHardSessionBack_WhenACheckInMovedIt()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);
        (await CheckInAsync(member, fatigue: 2, soreness: 2, sleep: 1)).EnsureSuccessStatusCode();
        var today = await TodayAsync(member);

        var answer = await member.Client.DeleteAsync($"/api/v1/training/sessions/{today.Id}/easy", Ct);

        Assert.Equal(HttpStatusCode.OK, answer.StatusCode);
        var sessions = await SessionsAsync(api, member.Id);
        var back = Assert.Single(sessions);
        Assert.Equal(Tuesday, back.LocalDate);
        Assert.Equal("R05", back.Recipe);
        Assert.Equal(TrainingSessionStates.Planned, back.State);
    }

    [Fact]
    public async Task MoveTrainingSession_ShouldMoveToADayTheRiderDoesNotRide_WhenTheSessionIsEasy()
    {
        // Tuesday and Thursday are the rider's days; a moved session may still go on Wednesday, which is neither.
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R02", 60));
        var session = await TodayAsync(member);

        var answer = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/move",
            new MoveTrainingSessionRequest { LocalDate = Wednesday }, Ct);

        Assert.Equal(HttpStatusCode.OK, answer.StatusCode);
        var moved = Assert.Single((await WeekAsync(member)).Sessions);
        Assert.Equal(Wednesday, moved.LocalDate);
        Assert.Equal(TrainingSessionStates.Moved, moved.State);
        Assert.Contains(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingMoved);
    }

    [Fact]
    public async Task MoveTrainingSession_ShouldRefuseTheDayBesideAnotherHardDay_WhenTheSessionIsHard()
    {
        // Friday carries the week's other hard day, so Thursday is refused back to back with it. Wednesday is the
        // nearest day that works, and the refusal names it.
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Friday, "R06", 60));
        var session = await TodayAsync(member);

        var refused = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/move",
            new MoveTrainingSessionRequest { LocalDate = Thursday }, Ct);

        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);
        var body = await refused.Content.ReadAsStringAsync(Ct);
        Assert.Contains("next to another hard day", body);
        Assert.Contains(Wednesday.ToString("yyyy-MM-dd"), body);
        // The refusal changed nothing.
        Assert.Equal(Tuesday, Assert.Single(await SessionsAsync(api, member.Id), s => s.Recipe == "R05").LocalDate);
    }

    [Fact]
    public async Task MoveTrainingSession_ShouldRefuseTheDayBesideTheLongRide_WhenTheSessionIsHard()
    {
        // Saturday sits next to Sunday's long ride; Friday, two days away from it, is the nearest day that works.
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Sunday, "R03", 180));
        var session = await TodayAsync(member);

        var refused = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/move",
            new MoveTrainingSessionRequest { LocalDate = Saturday }, Ct);

        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);
        var body = await refused.Content.ReadAsStringAsync(Ct);
        Assert.Contains("next to the long ride", body);
        Assert.Contains(Friday.ToString("yyyy-MM-dd"), body);
    }

    [Fact]
    public async Task MoveTrainingSession_ShouldLeaveAMovedSessionAlone_WhenTheNightWritesTheWeekAgain()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R02", 60));
        var session = await TodayAsync(member);
        (await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/move",
            new MoveTrainingSessionRequest { LocalDate = Wednesday }, Ct)).EnsureSuccessStatusCode();

        // The rider's own midnight has passed: the sweep writes the week again, and the moved session stays put.
        ((FakeTime)api.Services.GetRequiredService<TimeProvider>()).Now = Now.AddDays(1).AddHours(-11);
        await Sweeper(api).RunOnceAsync(Ct);

        var moved = Assert.Single(await SessionsAsync(api, member.Id), s => s.LocalDate == Wednesday);
        Assert.Equal(TrainingSessionStates.Moved, moved.State);
        Assert.Equal(session.Id, moved.Id);
    }

    [Fact]
    public async Task SkipTrainingSession_ShouldKeepItOnItsOwnDay_WhenTheRiderSkipsIt()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Thursday, "R06", 60));
        var session = await TodayAsync(member);

        var answer = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.Tired }, Ct);

        Assert.Equal(HttpStatusCode.OK, answer.StatusCode);
        var week = (await answer.Content.ReadFromJsonAsync<TrainingWeeksResponse>(Ct))!.Weeks[0];
        var skipped = Assert.Single(week.Sessions, s => s.LocalDate == Tuesday);
        Assert.Equal(TrainingSessionStates.Skipped, skipped.State);
        Assert.Equal(TrainingSkipReasons.Tired, skipped.SkipReason);
        // Nothing is piled onto a later day.
        Assert.Equal(2, week.Sessions.Length);
        Assert.Equal(1, week.SkipsThisWeek);
        Assert.Contains(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingSkipped);
    }

    [Fact]
    public async Task SkipTrainingSession_ShouldSayHowManyWereSkipped_WhenItIsTheSecondSkip()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Monday, "R05", 60), (Tuesday, "R06", 60), (Thursday, "R02", 60),
            (Sunday, "R03", 180));
        var sessions = await WeekAsync(member);
        var monday = sessions.Sessions[0];
        var second = Assert.Single(sessions.Sessions, s => s.LocalDate == Tuesday);

        (await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{monday.Id}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.NoTime }, Ct)).EnsureSuccessStatusCode();
        var answer = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{second.Id}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.Ill }, Ct);

        // The week says how many have been skipped, and the app asks about the rest from the second one.
        var asked = (await answer.Content.ReadFromJsonAsync<TrainingWeeksResponse>(Ct))!.Weeks[0];
        Assert.Equal(2, asked.SkipsThisWeek);

        var rest = await member.Client.PostAsJsonAsync($"/api/v1/training/sessions/{second.Id}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.Ill, RestOfWeek = true }, Ct);

        var done = (await rest.Content.ReadFromJsonAsync<TrainingWeeksResponse>(Ct))!.Weeks[0];
        Assert.All(done.Sessions, s => Assert.Equal(TrainingSessionStates.Skipped, s.State));
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldOfferTheDaysASessionCanMoveTo_WhenItIsStillToBeRidden()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Sunday, "R03", 180));

        var today = await TodayAsync(member);

        Assert.True(today.CanMakeEasy);
        Assert.NotEmpty(today.Move);
        Assert.All(today.Move, day => Assert.Equal(day.Allowed, day.Reason is null));
        // Saturday is refused because it is next to the long ride, in the words the sheet shows.
        Assert.Equal(MoveRefusals.NextToLongRide, Assert.Single(today.Move, d => d.LocalDate == Saturday).Reason);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldNotReturnTheCheckInAnswers_WhenTheDayWasMadeEasy()
    {
        // The week says why in the four words the owner approved and nothing more: nobody, the owner included, reads
        // the check-in back through the plan.
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60));
        await ConsentAsync(member);
        (await CheckInAsync(member, fatigue: 5, soreness: 5, sleep: 1, mood: 1, stress: 5, motivation: 1))
            .EnsureSuccessStatusCode();

        var json = await member.Client.GetStringAsync("/api/v1/training/week", Ct);

        Assert.Contains(TrainingEasyReasons.SleptPoorly, json);
        Assert.DoesNotContain("\"fatigue\"", json);
        Assert.DoesNotContain("\"soreness\"", json);
        Assert.DoesNotContain("\"mood\"", json);
        Assert.DoesNotContain("\"stress\"", json);
        Assert.DoesNotContain("\"sleep\"", json);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldAnnounceTheDayAtSeven_WhenTheRiderHasASessionToday()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 24, 7, 0, 0, TimeSpan.Zero));
        var member = await RiderAsync(api, (Tuesday, "R05", 60));

        var sweeper = Sweeper(api);
        await sweeper.RunOnceAsync(Ct);
        await sweeper.RunOnceAsync(Ct);

        // One notification for the day, however often the sweep runs.
        var notice = Assert.Single(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingToday);
        Assert.Equal("Strong and steady", notice.Subject);
        Assert.Equal(Tuesday, notice.Notice!.LocalDate);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldNotAnnounceTheDay_WhenItIsBeforeSeven()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 24, 6, 59, 0, TimeSpan.Zero));
        var member = await RiderAsync(api, (Tuesday, "R05", 60));

        await Sweeper(api).RunOnceAsync(Ct);

        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingToday);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldNotAnnounceARestDay_WhenTheDayHasNoSession()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 24, 7, 30, 0, TimeSpan.Zero));
        var member = await RiderAsync(api, (Thursday, "R05", 60));

        await Sweeper(api).RunOnceAsync(Ct);

        Assert.DoesNotContain(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingToday);
    }

    [Theory]
    [InlineData("easy")]
    [InlineData("move")]
    [InlineData("skip")]
    [InlineData("back")]
    public async Task TrainingSessionActions_ShouldAnswer404_WhenAnotherMemberAsks(string action)
    {
        await using var api = await StartAsync();
        var rider = await RiderAsync(api, (Tuesday, "R05", 60));
        var other = await NewMemberAsync(api, "Someone Else");
        var session = await TodayAsync(rider);

        var answer = action switch
        {
            "easy" => await other.Client.PostAsync($"/api/v1/training/sessions/{session.Id}/easy", null, Ct),
            "back" => await other.Client.DeleteAsync($"/api/v1/training/sessions/{session.Id}/easy", Ct),
            "move" => await other.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/move",
                new MoveTrainingSessionRequest { LocalDate = Wednesday }, Ct),
            _ => await other.Client.PostAsJsonAsync($"/api/v1/training/sessions/{session.Id}/skip",
                new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.Tired }, Ct),
        };

        Assert.Equal(HttpStatusCode.NotFound, answer.StatusCode);
        // The other member's ask changed nothing.
        Assert.Equal(TrainingSessionStates.Planned, Assert.Single(await SessionsAsync(api, rider.Id)).State);
    }

    [Fact]
    public async Task Notifications_ShouldCarryTheSessionTheirSentenceIsAbout_WhenTheDayWasMadeEasy()
    {
        await using var api = await StartAsync();
        var member = await RiderAsync(api, (Tuesday, "R05", 60), (Sunday, "R03", 180));
        await ConsentAsync(member);
        (await CheckInAsync(member, fatigue: 2, soreness: 2, sleep: 1)).EnsureSuccessStatusCode();

        var notification = Assert.Single(await NotificationsAsync(member), n => n.Type == NotificationTypes.TrainingEasy);
        var notice = notification.Notice!;

        Assert.Equal(Thursday, notice.EasyMovedTo);
        Assert.Equal(TrainingEasyReasons.SleptPoorly, notice.EasyReason);
        Assert.Equal("Easy ride", notice.EnglishName);
        Assert.NotEqual("", notice.ItalianName);
        Assert.Equal(JsonValueKind.Object, JsonDocument.Parse(JsonSerializer.Serialize(notice)).RootElement.ValueKind);
    }
}
