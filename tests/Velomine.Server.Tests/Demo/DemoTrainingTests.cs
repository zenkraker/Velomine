using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Demo;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Demo;

/// <summary>
/// The demo rider's auto training: the week the seed writes, every number in it coming from the training code rather
/// than from the seed, the week coming back after the night, and the demo letting a visitor change it but not switch
/// it off.
/// </summary>
public sealed class DemoTrainingTests(PostgresFixture postgres)
{
    private const string Rider = "demo-rider@velomine.eu";

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartDemoAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Demo:Enabled", "true"));

    private static async Task ResetAsync(TestApi api)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<DemoData>().ResetAsync(Ct);
    }

    /// <summary>The demo rider's own clock, as the endpoints read it.</summary>
    private static async Task<MemberClock> ClockAsync(VelomineDbContext db, TimeProvider time)
    {
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Email == Rider, Ct);
        return MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
    }

    [Fact]
    public async Task DemoData_ShouldSeedAWeekInProgress_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var time = api.Services.GetRequiredService<TimeProvider>();
        var clock = await ClockAsync(db, time);
        var weekStart = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Email == Rider, Ct);
        var plan = await db.TrainingPlans.AsNoTracking().SingleAsync(p => p.UserId == user.Id, Ct);
        var sessions = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id).OrderBy(s => s.LocalDate).ToListAsync(Ct);

        Assert.True(plan.IsOn);
        Assert.Contains((int)clock.Today.DayOfWeek, plan.Days);
        Assert.InRange(plan.HoursPerWeek, 1, 30);

        // Today open, the rides the script wrote done, the gap between them skipped with a reason, the week ahead planned.
        var today = sessions.Single(s => s.LocalDate == clock.Today);
        Assert.Equal(TrainingSessionStates.Planned, today.State);
        Assert.Null(today.RideId);
        Assert.All(sessions.Where(s => s.LocalDate < clock.Today && s.LocalDate >= weekStart),
            s => Assert.True(s.State is TrainingSessionStates.Done or TrainingSessionStates.Skipped, $"{s.LocalDate} is {s.State}"));
        var done = sessions.Where(s => s.State == TrainingSessionStates.Done).ToArray();
        Assert.True(done.Length >= 2, $"only {done.Length} sessions were ridden");
        Assert.All(done, s => Assert.NotNull(s.RideId));
        var skipped = Assert.Single(sessions, s => s.State == TrainingSessionStates.Skipped);
        Assert.NotNull(skipped.SkipReason);
        Assert.Contains(sessions, s => s.LocalDate >= clock.Today && s.State == TrainingSessionStates.Planned);
        // A day of the week has no session, so the move sheet has somewhere to offer.
        Assert.NotEqual(7, sessions.Count(s => s.LocalDate >= weekStart));

        // The page a visitor opens shows the same week, with a score on every session the rider rode.
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);
        var weeks = await rider.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct);
        var thisWeek = weeks!.Weeks.Single(w => w.Start == weekStart);
        Assert.Equal(clock.Today, thisWeek.Sessions.Single(s => s.LocalDate == clock.Today).LocalDate);
        Assert.All(thisWeek.Sessions.Where(s => s.State == TrainingSessionStates.Done),
            s => Assert.True(s.Result!.Score > 0, $"{s.LocalDate} scored {s.Result.Score}"));
        Assert.Equal(TrainingSkipReasons.Ill, Assert.Single(thisWeek.Sessions, s => s.LocalDate == skipped.LocalDate).SkipReason);
    }

    [Fact]
    public async Task DemoData_ShouldTakeEverySeededNumberFromTheTrainingCode_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var time = api.Services.GetRequiredService<TimeProvider>();
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Email == Rider, Ct);
        var sessions = await db.TrainingSessions.AsNoTracking().Where(s => s.UserId == user.Id).ToListAsync(Ct);
        Assert.NotEmpty(sessions);

        // A session is stored as a recipe and a day's minutes, exactly as the planner stores one: its block percentages
        // are the code's own, so no number in the seed can disagree with what the app would compute.
        foreach (var session in sessions)
        {
            var (recipe, blocks) = SessionPlan.For(Recipes.ByCode(session.Recipe), session.Minutes);
            Assert.Equal(recipe.Code, session.Recipe);
            Assert.Equal(SessionPlan.Percents(blocks), session.BlockPercents);
        }

        // A done session's score is computed from the ride the script wrote on its day, and its planned effort from the
        // recipe: neither is written by the seed, which is why the two follow the code for every session.
        var results = await SessionScore.ForAsync(db, sessions, user, time, Ct);
        var done = sessions.Where(s => s.State == TrainingSessionStates.Done).ToArray();
        Assert.True(done.Length >= 2, $"only {done.Length} sessions were ridden");
        foreach (var session in done)
        {
            var result = results[session.Id];
            Assert.True(result.Score > 0, $"{session.LocalDate} scored {result.Score}");
            Assert.Equal(SessionPlan.PlannedScore(session.Recipe, session.Minutes), result.PlannedEffort);
            Assert.Equal(SessionPlan.PlannedMinutes(session.Recipe, session.Minutes), result.PlannedMinutes);
        }

        // And the week the app reads carries the same arithmetic, session by session.
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);
        var weeks = await rider.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct);
        var shown = weeks!.Weeks.SelectMany(w => w.Sessions).ToArray();
        Assert.NotEmpty(shown);
        foreach (var session in shown.Where(s => s.Result is not null))
        {
            Assert.Equal(SessionPlan.PlannedScore(session.Recipe, session.Minutes), session.Result!.PlannedEffort);
            Assert.Equal(results[session.Id].Score, session.Result.Score);
        }
    }

    [Fact]
    public async Task DemoData_ShouldStoreTheGoalItsOwnRulesSuggest_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var time = api.Services.GetRequiredService<TimeProvider>();
        var clock = await ClockAsync(db, time);
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Email == Rider, Ct);
        var plan = await db.TrainingPlans.AsNoTracking().SingleAsync(p => p.UserId == user.Id, Ct);

        // The seed does not pick a goal of its own: the rules over the seeded rides do, so the reason the Training page
        // shows under the goal is always that goal's reason.
        var suggestion = TrainingGoalSuggestion.For(await TrainingGoalSuggestion.ReadAsync(db, user.Id, clock, null, Ct));
        Assert.Equal(suggestion.Goal, plan.Goal);
        Assert.Equal(TrainingGoals.Fitter, plan.Goal);
        Assert.Equal(TrainingGoalReasons.RegularRider, suggestion.Reason);

        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);
        var response = await rider.GetFromJsonAsync<TrainingPlanResponse>("/api/v1/training/plan", Ct);
        Assert.True(response!.On);
        Assert.Equal(plan.Goal, response.Goal);
        Assert.Equal(suggestion.Reason, response.SuggestionReason);
        Assert.Equal(WeekDays.Name(clock.FirstDayOfWeek), response.FirstDayOfWeek);
    }

    /// <summary>
    /// The week's rows as plain text: a reset makes the rides again, so their ids move, and what must match is what the
    /// week says — its days, its recipes, its minutes, the state of each session and the ride that was it.
    /// </summary>
    private static async Task<string[]> WeekAsync(TestApi api)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.AsNoTracking().SingleAsync(u => u.Email == Rider, Ct);
        var plan = await db.TrainingPlans.AsNoTracking().SingleAsync(p => p.UserId == user.Id, Ct);
        var rides = await db.Rides.AsNoTracking().ToDictionaryAsync(r => r.Id, r => r.FileName, Ct);
        var sessions = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == user.Id).OrderBy(s => s.LocalDate).ToListAsync(Ct);
        return
        [
            $"plan {plan.Goal} {string.Join(',', plan.Days)} {plan.HoursPerWeek} {plan.LongRideDay} {plan.IsOn} {plan.LastPlannedFor}",
            .. sessions.Select(s => string.Join('|',
                s.LocalDate, s.Recipe, s.Minutes, string.Join(',', s.BlockPercents), s.State, s.SkipReason,
                s.RideId is { } ride ? rides[ride] : "-", s.EasyReason, s.EasyMovedTo, s.OriginalRecipe)),
        ];
    }

    [Fact]
    public async Task DemoData_ShouldSeedTheSameWeek_WhenTheDemoIsResetTwice()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var seeded = await WeekAsync(api);

        await ResetAsync(api);

        Assert.Equal(seeded, await WeekAsync(api));
    }

    [Fact]
    public async Task DemoData_ShouldRestoreTheSeededWeek_WhenAVisitorChangedIt()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var seeded = await WeekAsync(api);
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);

        // A visitor does what the demo invites: today becomes easy, today is then skipped, and a session moves when the
        // week still has a day left to move it to.
        var weeks = (await rider.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!;
        var today = weeks.Weeks[0].Sessions.Single(s => s.CanMakeEasy);
        Assert.Equal(HttpStatusCode.OK, (await rider.PostAsync($"/api/v1/training/sessions/{today.Id}/easy", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await rider.PostAsJsonAsync(
            $"/api/v1/training/sessions/{today.Id}/skip", new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.Tired }, Ct)).StatusCode);
        var mover = weeks.Weeks[0].Sessions.FirstOrDefault(s => s.Move.Any(m => m.Allowed));
        if (mover is not null)
        {
            var day = mover.Move.First(m => m.Allowed).LocalDate;
            Assert.Equal(HttpStatusCode.OK, (await rider.PostAsJsonAsync(
                $"/api/v1/training/sessions/{mover.Id}/move", new MoveTrainingSessionRequest { LocalDate = day }, Ct)).StatusCode);
        }

        Assert.NotEqual(seeded, await WeekAsync(api));

        await ResetAsync(api);

        // Whatever the visitor did is gone: the same week as a fresh demo has.
        Assert.Equal(seeded, await WeekAsync(api));
    }

    [Fact]
    public async Task DemoLock_ShouldLetAVisitorChangeTheWeek_ButNotTurnAutoTrainingOff_WhenTheServerIsADemo()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);

        // Changing the setup is what a visitor is meant to try.
        var setup = await rider.PutAsJsonAsync("/api/v1/training/plan", new SaveTrainingPlanRequest(
            TrainingGoals.Fitter, ["monday", "wednesday", "friday", "sunday"], 8, "sunday",
            MaxHeartRateKnown: false, MaxHeartRate: null, BirthYear: null, TimeZone: "Europe/Madrid"), Ct);
        Assert.Equal(HttpStatusCode.OK, setup.StatusCode);

        var weeks = (await rider.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!;
        var week = weeks.Weeks[0];

        // Making today easy and skipping a session are allowed too.
        var easy = await rider.PostAsync($"/api/v1/training/sessions/{week.Sessions.Single(s => s.CanMakeEasy).Id}/easy", null, Ct);
        Assert.Equal(HttpStatusCode.OK, easy.StatusCode);
        var after = (await easy.Content.ReadFromJsonAsync<TrainingWeeksResponse>(Ct))!;
        var open = after.Weeks[0].Sessions.First(s => s.State is TrainingSessionStates.Planned or TrainingSessionStates.Easy);
        var skip = await rider.PostAsJsonAsync($"/api/v1/training/sessions/{open.Id}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.NoTime }, Ct);
        Assert.Equal(HttpStatusCode.OK, skip.StatusCode);

        // Moving is allowed as well. On the week's last day there is no day left to move to: that is the product's own
        // answer, and it is not the demo refusing it.
        var move = after.Weeks[0].Sessions.FirstOrDefault(s => s.Move.Any(m => m.Allowed));
        if (move is not null)
        {
            var moved = await rider.PostAsJsonAsync($"/api/v1/training/sessions/{move.Id}/move",
                new MoveTrainingSessionRequest { LocalDate = move.Move.First(m => m.Allowed).LocalDate }, Ct);
            Assert.Equal(HttpStatusCode.OK, moved.StatusCode);
        }

        // Turning auto training off would take the week away from every visitor until 03:00 UTC, so the demo refuses it.
        var off = await rider.DeleteAsync("/api/v1/training/plan", Ct);
        Assert.Equal(HttpStatusCode.Forbidden, off.StatusCode);
        Assert.Contains(DemoLock.Code, await off.Content.ReadAsStringAsync(Ct));
        Assert.True((await rider.GetFromJsonAsync<TrainingPlanResponse>("/api/v1/training/plan", Ct))!.On);
    }
}
