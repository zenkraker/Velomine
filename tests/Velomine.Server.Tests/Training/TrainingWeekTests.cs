using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The sweep that writes the week and the endpoint that reads it: the plan is the caller's own, the week is written a
/// day at a time in the member's own calendar, and a day already done or moved is never rewritten.
/// </summary>
public sealed class TrainingWeekTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Tuesday 24 November 2026 at midday UTC, in a week that starts on Monday.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 12, 0, 0, TimeSpan.Zero);

    private static readonly DateOnly Monday = new(2026, 11, 23);
    private static readonly DateOnly Tuesday = Monday.AddDays(1);
    private static readonly DateOnly Thursday = Monday.AddDays(3);
    private static readonly DateOnly Sunday = Monday.AddDays(6);

    private Task<TestApi> StartAsync(DateTimeOffset? now = null, Action<IWebHostBuilder>? extra = null) =>
        TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FakeTime { Now = now ?? Now }));
            extra?.Invoke(b);
        });

    private static async Task<TestMember> NewMemberAsync(TestApi api, string name = "Test Rider", int? ftpW = null)
    {
        var member = await api.NewMemberAsync(name);
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest(name, null, null, null, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        if (ftpW is { } ftp)
            (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(ftp), Ct))
                .EnsureSuccessStatusCode();
        return member;
    }

    private static Task<HttpResponseMessage> SaveAsync(HttpClient client, string[] days, int hours = 6) =>
        client.PutAsJsonAsync("/api/v1/training/plan",
            new SaveTrainingPlanRequest(
                TrainingGoals.Fitter, days, hours, null, true, 180, 1988, null), Ct);

    /// <summary>
    /// Five weeks of steady riding, a hundred of load on each of five days: a rider past the gentle base block whose
    /// readiness stays out of the rest band, so the week is planned as a normal building week.
    /// </summary>
    private static async Task WithRidingHistoryAsync(TestApi api, Guid userId, int weeks = 5)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        for (var week = 1; week <= weeks; week++)
        {
            for (var day = 0; day < 5; day++)
            {
                db.Rides.Add(new Ride
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Status = RideStatus.Ready,
                    StartTime = new DateTimeOffset(
                        Monday.AddDays(-7 * week + day).ToDateTime(new TimeOnly(7, 0)), TimeSpan.Zero),
                    UtcOffsetMinutes = 0,
                    MovingS = 3600,
                    Tss = 100,
                });
            }
        }
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>The rider rides the week that was planned: one finished ride on each of its days.</summary>
    private static async Task RodeAsync(TestApi api, Guid userId, IEnumerable<TrainingWeekSession> sessions)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        foreach (var session in sessions)
        {
            db.Rides.Add(new Ride
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Status = RideStatus.Ready,
                StartTime = new DateTimeOffset(session.LocalDate.ToDateTime(new TimeOnly(9, 0)), TimeSpan.Zero),
                UtcOffsetMinutes = 0,
                MovingS = 3600,
                Tss = 100,
            });
        }
        await db.SaveChangesAsync(Ct);
    }

    private static async Task StartPlanAsync(
        TestApi api, TestMember member, string[] days, int hours = 6, bool history = true)
    {
        if (history) await WithRidingHistoryAsync(api, member.Id);
        (await SaveAsync(member.Client, days, hours)).EnsureSuccessStatusCode();
    }

    private static TrainingPlanSweeper Sweeper(TestApi api, bool autoEnabled = true) => new(
        api.Services.GetRequiredService<IServiceScopeFactory>(),
        Options.Create(new TrainingOptions { AutoEnabled = autoEnabled }),
        NullLogger<TrainingPlanSweeper>.Instance);

    private static async Task<List<TrainingSession>> SessionsAsync(TestApi api, Guid userId, DateOnly from, DateOnly to)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == userId && s.LocalDate >= from && s.LocalDate <= to)
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(Ct);
    }

    private static async Task<DateOnly?> LastPlannedForAsync(TestApi api, Guid userId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return (await db.TrainingPlans.AsNoTracking().FirstAsync(p => p.UserId == userId, Ct)).LastPlannedFor;
    }

    private static async Task<TrainingWeeksResponse> WeekAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!;

    [Fact]
    public async Task TrainingPlanSweeper_ShouldWriteTheWeeksSessions_WhenTheRiderIsDue()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);

        await Sweeper(api).RunOnceAsync(Ct);

        var sessions = await SessionsAsync(api, member.Id, Monday, Sunday);
        Assert.Equal([Tuesday, Thursday, Sunday], sessions.Select(s => s.LocalDate));
        Assert.All(sessions, session =>
        {
            Assert.Equal(TrainingSessionStates.Planned, session.State);
            Assert.NotEmpty(session.Recipe);
            Assert.NotEmpty(session.BlockPercents);
            Assert.True(session.Minutes > 0);
        });
        // The week is written for today, so the next sweep waits for tomorrow.
        Assert.Equal(Tuesday, await LastPlannedForAsync(api, member.Id));
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldWriteNothing_WhenTheOperatorSwitchIsOff()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);

        await Sweeper(api, autoEnabled: false).RunOnceAsync(Ct);

        Assert.Empty(await SessionsAsync(api, member.Id, Monday, Sunday));
        Assert.Null(await LastPlannedForAsync(api, member.Id));
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldWriteNothing_WhenTheRiderTurnedAutoTrainingOff()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        (await member.Client.DeleteAsync("/api/v1/training/plan", Ct)).EnsureSuccessStatusCode();

        await Sweeper(api).RunOnceAsync(Ct);

        Assert.Empty(await SessionsAsync(api, member.Id, Monday, Sunday));
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldPlanTheDayOnce_WhenItRunsAgainOnTheSameDay()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);

        var sweeper = Sweeper(api);
        await sweeper.RunOnceAsync(Ct);
        var first = await SessionsAsync(api, member.Id, Monday, Sunday);
        await sweeper.RunOnceAsync(Ct);
        var second = await SessionsAsync(api, member.Id, Monday, Sunday);

        Assert.Equal(first.Select(s => s.Id), second.Select(s => s.Id));
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldRewriteTomorrowsDays_WhenTheLocalDatePassed()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        var sweeper = Sweeper(api);
        await sweeper.RunOnceAsync(Ct);
        var days = await SessionsAsync(api, member.Id, Monday, Sunday);
        var sunday = Assert.Single(days, s => s.LocalDate == Sunday);

        // The sweep runs again after the member's midnight: today and later are written again, yesterday is not.
        ((FakeTime)api.Services.GetRequiredService<TimeProvider>()).Now = Now.AddDays(4).AddHours(-11);
        await sweeper.RunOnceAsync(Ct);

        var rewritten = await SessionsAsync(api, member.Id, Monday, Sunday);
        Assert.Equal(Tuesday, Assert.Single(rewritten, s => s.LocalDate == Tuesday).LocalDate);
        Assert.NotEqual(sunday.Id, Assert.Single(rewritten, s => s.LocalDate == Sunday).Id);
        Assert.Equal(Monday.AddDays(5), await LastPlannedForAsync(api, member.Id));
        // Tuesday and Thursday are behind the new today: they stay exactly as they were.
        Assert.Equal(days.Where(s => s.LocalDate < Thursday).Select(s => s.Id),
            rewritten.Where(s => s.LocalDate < Thursday).Select(s => s.Id));
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldLeaveADoneDay_WhenTheWeekIsWrittenAgain()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        var sweeper = Sweeper(api);
        await sweeper.RunOnceAsync(Ct);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var thursday = await db.TrainingSessions.FirstAsync(s => s.UserId == member.Id && s.LocalDate == Thursday, Ct);
            thursday.State = TrainingSessionStates.Done;
            thursday.RideId = null;
            await db.SaveChangesAsync(Ct);
        }

        ((FakeTime)api.Services.GetRequiredService<TimeProvider>()).Now = Now.AddDays(3);
        await sweeper.RunOnceAsync(Ct);

        var sessions = await SessionsAsync(api, member.Id, Monday, Sunday);
        var done = Assert.Single(sessions, s => s.LocalDate == Thursday);
        Assert.Equal(TrainingSessionStates.Done, done.State);
        Assert.Equal(3, sessions.Count);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldPlanNextWeekToo_WhenTheDayIsTheLastOfTheWeek()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 29, 12, 0, 0, TimeSpan.Zero));
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);

        await Sweeper(api).RunOnceAsync(Ct);

        // This week keeps its last day, and next week is written in full as the preview the rider reads that evening.
        var thisWeek = await SessionsAsync(api, member.Id, Monday, Sunday);
        Assert.Equal([Sunday], thisWeek.Select(s => s.LocalDate));
        var nextWeek = await SessionsAsync(api, member.Id, Monday.AddDays(7), Sunday.AddDays(7));
        Assert.Equal([Tuesday.AddDays(7), Thursday.AddDays(7), Sunday.AddDays(7)], nextWeek.Select(s => s.LocalDate));
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldAnswerTheWeekWithItsLoad_WhenTheSweepHasPlannedIt()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api, ftpW: 250);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        await Sweeper(api).RunOnceAsync(Ct);

        var week = Assert.Single((await WeekAsync(member.Client)).Weeks);

        Assert.Equal(Monday, week.Start);
        Assert.Equal(Sunday, week.End);
        Assert.Equal(3, week.Sessions.Length);
        Assert.Equal(Math.Round(week.Sessions.Sum(s => SessionScore(s.Recipe, s.Minutes)), 1), week.PlannedLoad);
        Assert.False(week.IsLighterWeek);
        Assert.Null(week.Note);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldGiveEverySessionItsTargets_WhenTheRiderHasAnFtp()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api, ftpW: 250);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        await Sweeper(api).RunOnceAsync(Ct);

        var week = Assert.Single((await WeekAsync(member.Client)).Weeks);

        // Tuesday's session is the week's first hard day: sweet spot, so 88 % FTP and up in watts.
        var hard = Assert.Single(week.Sessions, s => s.LocalDate == Tuesday);
        Assert.True(Recipes.ByCode(hard.Recipe).IsQuality);
        Assert.NotEmpty(hard.Blocks);
        Assert.All(hard.Blocks, block =>
        {
            Assert.NotNull(block.WattsLow);
            Assert.True(block.WattsHigh > block.WattsLow);
            Assert.InRange(block.FeelLow, 1, 10);
        });
        Assert.DoesNotContain(hard.Notes, note => note.Code == "add_power_meter");
        // The rider reads the plain name and its line, never the recipe code alone.
        Assert.Equal("Strong and steady", hard.EnglishName);
        Assert.NotEqual("", hard.ItalianName);
        Assert.NotEmpty(hard.EnglishLine);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldSayTheWattTargetsNeedAMeter_WhenTheRiderHasNone()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        await Sweeper(api).RunOnceAsync(Ct);

        var week = Assert.Single((await WeekAsync(member.Client)).Weeks);

        var session = week.Sessions[0];
        Assert.All(session.Blocks, block => Assert.Null(block.WattsLow));
        Assert.Contains(session.Notes, note => note.Code == "add_power_meter");
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldAnswer404_WhenTheMemberHasNoAutoTraining()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var answer = await member.Client.GetAsync("/api/v1/training/week", Ct);

        Assert.Equal(HttpStatusCode.NotFound, answer.StatusCode);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldAnswer404_WhenTheMemberTurnedAutoTrainingOff()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        (await SaveAsync(member.Client, ["tuesday", "thursday", "sunday"])).EnsureSuccessStatusCode();
        (await member.Client.DeleteAsync("/api/v1/training/plan", Ct)).EnsureSuccessStatusCode();

        Assert.Equal(HttpStatusCode.NotFound,
            (await member.Client.GetAsync("/api/v1/training/week", Ct)).StatusCode);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldShowOnlyTheCallersWeek_WhenAnotherMemberHasAPlan()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        await StartPlanAsync(api, rider, ["tuesday", "thursday", "sunday"], hours: 8);
        await StartPlanAsync(api, other, ["monday", "wednesday"], hours: 3);
        await Sweeper(api).RunOnceAsync(Ct);

        var mine = Assert.Single((await WeekAsync(rider.Client)).Weeks);
        var theirs = Assert.Single((await WeekAsync(other.Client)).Weeks);

        Assert.Equal([Tuesday, Thursday, Sunday], mine.Sessions.Select(s => s.LocalDate));
        Assert.Equal([Monday.AddDays(2)], theirs.Sessions.Select(s => s.LocalDate));
        Assert.NotEqual(mine.PlannedLoad, theirs.PlannedLoad);

        // Nothing of the other member's week is reachable: the plan is keyed by the caller.
        var sessions = await SessionsAsync(api, rider.Id, Monday, Sunday);
        Assert.All(sessions, session => Assert.Equal(rider.Id, session.UserId));
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldShowNextWeekAsAPreview_WhenTheDayIsTheLastOfTheWeek()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 29, 12, 0, 0, TimeSpan.Zero));
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        await Sweeper(api).RunOnceAsync(Ct);

        var weeks = (await WeekAsync(member.Client)).Weeks;

        Assert.Equal(2, weeks.Length);
        Assert.Equal(Monday, weeks[0].Start);
        Assert.Equal(Monday.AddDays(7), weeks[1].Start);
        Assert.All(weeks[1].Sessions, session => Assert.True(session.LocalDate >= Monday.AddDays(7)));
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldReadTheLighterWeekInTheWeeksOwnWords_WhenItIsOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var plan = await db.TrainingPlans.FirstAsync(p => p.UserId == member.Id, Ct);
            plan.LighterWeeks = [Monday];
            await db.SaveChangesAsync(Ct);
        }

        await Sweeper(api).RunOnceAsync(Ct);

        var week = Assert.Single((await WeekAsync(member.Client)).Weeks);
        Assert.True(week.IsLighterWeek);
        Assert.Equal("easy_week", week.Note!.Code);
        Assert.Equal("Easy week: your body gets stronger while it rests", week.Note.English);
        // One short hard day at most, and every word a rider reads keeps off the planner's jargon.
        Assert.True(week.Sessions.Count(s => Recipes.ByCode(s.Recipe).IsQuality) <= 1);
        Assert.DoesNotContain("quality", week.Note.English, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task GetTrainingWeek_ShouldPlanTheRestOfTheWeek_WhenAutoTrainingIsSwitchedOnMidWeek()
    {
        await using var api = await StartAsync(new DateTimeOffset(2026, 11, 26, 9, 0, 0, TimeSpan.Zero));
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["monday", "wednesday", "friday"]);

        await Sweeper(api).RunOnceAsync(Ct);

        var session = Assert.Single(await SessionsAsync(api, member.Id, Monday, Sunday));
        Assert.Equal(Monday.AddDays(4), session.LocalDate);
    }

    [Fact]
    public async Task TrainingPlanSweeper_ShouldMakeTheFourthWeekLighter_WhenThreeWeeksWereBuilt()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await StartPlanAsync(api, member, ["tuesday", "thursday", "sunday"]);
        var clock = (FakeTime)api.Services.GetRequiredService<TimeProvider>();
        var sweeper = Sweeper(api);

        for (var week = 0; week < 4; week++)
        {
            await sweeper.RunOnceAsync(Ct);
            var weeks = (await WeekAsync(member.Client)).Weeks;
            Assert.Equal(Tuesday.AddDays(7 * week), weeks[0].Sessions[0].LocalDate);
            Assert.Equal(week == 3, weeks[0].IsLighterWeek);
            // He rides what was planned, so the next week has a normal week behind it.
            await RodeAsync(api, member.Id, weeks[0].Sessions);
            // The next sweep is due only after the member's own midnight, and the access token lasts fifteen minutes.
            clock.Now = clock.Now.AddDays(7);
            member = member with { Client = await api.SignedInClientAsync(member.Email, TestApi.MemberPassword) };
        }

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var plan = await db.TrainingPlans.AsNoTracking().FirstAsync(p => p.UserId == member.Id, Ct);
        Assert.Equal([Monday.AddDays(21)], plan.LighterWeeks);
    }

    [Fact]
    public void TrainingSetup_ShouldRegisterTheSweepOnly_WhenBackgroundWorkIsEnabled()
    {
        static IServiceCollection Setup(bool background)
        {
            var services = new ServiceCollection();
            services.AddLogging();
            services.AddTraining(new ConfigurationBuilder().AddInMemoryCollection(
                new Dictionary<string, string?> { ["Velomine:Background:Enabled"] = background.ToString() }).Build());
            return services;
        }

        Assert.Contains(Setup(true), d => d.ServiceType == typeof(Microsoft.Extensions.Hosting.IHostedService));
        Assert.DoesNotContain(Setup(false), d => d.ServiceType == typeof(Microsoft.Extensions.Hosting.IHostedService));
    }

    private static double SessionScore(string recipe, int minutes) =>
        SessionPlan.PlannedScore(SessionPlan.For(Recipes.ByCode(recipe), minutes).Blocks);
}
