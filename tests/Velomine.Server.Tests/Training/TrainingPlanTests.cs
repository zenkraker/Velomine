using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// Auto training's setup and its switch: one plan per member, owner only, and turning it off keeps the sessions already
/// ridden. The week follows the member's own clock, so a test fixes both the instant and the zone.
/// </summary>
public sealed class TrainingPlanTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>A Tuesday at midday UTC, so "today" and "this week" are known.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 24, 12, 0, 0, TimeSpan.Zero);

    private static readonly DateOnly Today = DateOnly.FromDateTime(Now.UtcDateTime);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    /// <summary>A member whose zone is UTC, so the fixed instant's date is their local date.</summary>
    private static async Task<TestMember> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var member = await api.NewMemberAsync(name);
        (await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest(name, null, null, null, "UTC", "monday"), Ct)).EnsureSuccessStatusCode();
        return member;
    }

    private static Task<HttpResponseMessage> SaveAsync(HttpClient client, SaveTrainingPlanRequest request) =>
        client.PutAsJsonAsync("/api/v1/training/plan", request, Ct);

    private static SaveTrainingPlanRequest Setup(
        string goal = TrainingGoals.Fitter,
        string[]? days = null,
        int hours = 6,
        string? longRideDay = null,
        bool maxHeartRateKnown = true,
        int? maxHeartRate = 180,
        int? birthYear = 1988,
        string? timeZone = null) =>
        new(goal, days ?? ["tuesday", "thursday", "sunday"], hours, longRideDay, maxHeartRateKnown, maxHeartRate, birthYear, timeZone);

    private static async Task<TrainingPlanResponse> PlanAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<TrainingPlanResponse>("/api/v1/training/plan", Ct))!;

    private static async Task<ProfileResponse> ProfileAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!;

    private static async Task<List<TrainingSession>> SessionsAsync(TestApi api, Guid userId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == userId).OrderBy(s => s.LocalDate).ToListAsync(Ct);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldStoreTheSetupAndTurnItOn_WhenTheRiderStarts()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var saved = await SaveAsync(member.Client, Setup(longRideDay: "sunday"));
        saved.EnsureSuccessStatusCode();
        var answer = (await saved.Content.ReadFromJsonAsync<TrainingPlanResponse>(Ct))!;

        Assert.True(answer.On);
        Assert.Equal(TrainingGoals.Fitter, answer.Goal);
        Assert.Equal(new[] { "sunday", "tuesday", "thursday" }, answer.Days);
        Assert.Equal(6, answer.HoursPerWeek);
        Assert.Equal("sunday", answer.LongRideDay);
        var plan = await PlanAsync(member.Client);
        Assert.True(plan.On);
        Assert.Equal(TrainingGoals.Fitter, plan.Goal);
    }

    [Fact]
    public async Task GetTrainingPlan_ShouldSuggestARegularStart_WhenTheMemberHasNoRidesYet()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var plan = await PlanAsync(member.Client);

        Assert.False(plan.On);
        Assert.Null(plan.Goal);
        Assert.Equal(TrainingGoals.Aerobic, plan.SuggestedGoal);
        Assert.Equal(TrainingGoalReasons.NotEnoughRiding, plan.SuggestionReason);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldSaveATypedMaximumThroughTheHeartRateHistory_WhenTheRiderTypesOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        (await SaveAsync(member.Client, Setup(maxHeartRate: 181))).EnsureSuccessStatusCode();

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == member.Id, Ct);
        Assert.Equal(181, user.MaxHeartRateBpm);
        Assert.Equal(HeartRateSources.Manual, user.MaxHeartRateSource);
        var history = await db.HeartRateHistory.AsNoTracking()
            .SingleAsync(h => h.UserId == member.Id && h.Kind == HeartRateKinds.Max, Ct);
        Assert.Equal(181, history.Bpm);
        Assert.Equal(HeartRateSources.Manual, history.Source);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldPutTheMaximumBackToTheEstimate_WhenTheRiderSaysTheyDoNotKnow()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        (await SaveAsync(member.Client, Setup(maxHeartRate: 181))).EnsureSuccessStatusCode();

        (await SaveAsync(member.Client, Setup(maxHeartRateKnown: false, maxHeartRate: null))).EnsureSuccessStatusCode();

        var profile = await ProfileAsync(member.Client);
        Assert.Equal(FtpSources.Estimate, profile.MaxHeartRateSource);
        // 208 − 0.7 × (2026 − 1988) = 181.4, rounded by Tanaka's estimate.
        Assert.Equal(181, profile.MaxHeartRate);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldRefuseTheSetup_WhenTheAccountHasNoYearOfBirthAndNoneIsSent()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var answer = await SaveAsync(member.Client, Setup(birthYear: null));

        Assert.Equal(HttpStatusCode.BadRequest, answer.StatusCode);
        Assert.False((await PlanAsync(member.Client)).On);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldStoreTheDevicesTimeZone_WhenTheAccountHasNone()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A fresh account has no zone: the other tests set one so "today" is known, this one must not.
        (await SaveAsync(member.Client, Setup(timeZone: "Europe/Rome"))).EnsureSuccessStatusCode();

        Assert.Equal("Europe/Rome", (await ProfileAsync(member.Client)).TimeZone);
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldStoreAZoneWithTheDevicesOffset_WhenTheDeviceSendsOnlyItsOffset()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        (await SaveAsync(member.Client, Setup() with { UtcOffsetMinutes = 60 })).EnsureSuccessStatusCode();

        var zone = (await ProfileAsync(member.Client)).TimeZone;
        Assert.False(string.IsNullOrEmpty(zone));
        Assert.Equal(TimeSpan.FromMinutes(60), TimeZoneInfo.FindSystemTimeZoneById(zone!).GetUtcOffset(Now));
    }

    [Fact]
    public async Task SaveTrainingPlan_ShouldKeepTheAccountsTimeZone_WhenItAlreadyHasOne()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        (await SaveAsync(member.Client, Setup(timeZone: "Europe/Rome"))).EnsureSuccessStatusCode();

        Assert.Equal("UTC", (await ProfileAsync(member.Client)).TimeZone);
    }

    [Fact]
    public async Task TurnOffTraining_ShouldDeleteTodayAndLaterSessions_WhenTheRiderTurnsItOff()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        (await SaveAsync(member.Client, Setup())).EnsureSuccessStatusCode();
        await AddSessionAsync(api, member.Id, Today.AddDays(-1));
        await AddSessionAsync(api, member.Id, Today);
        await AddSessionAsync(api, member.Id, Today.AddDays(3));

        var answer = await member.Client.DeleteAsync("/api/v1/training/plan", Ct);
        answer.EnsureSuccessStatusCode();

        var left = await SessionsAsync(api, member.Id);
        Assert.Equal(new[] { Today.AddDays(-1) }, left.Select(s => s.LocalDate));
        var plan = await PlanAsync(member.Client);
        Assert.False(plan.On);
        // The setup stays, so turning it on again opens pre-filled.
        Assert.Equal(TrainingGoals.Fitter, plan.Goal);
        Assert.Equal(6, plan.HoursPerWeek);
    }

    [Fact]
    public async Task TrainingPlan_ShouldNotBeReadOrChanged_WhenTheRequestComesFromAnotherMember()
    {
        await using var api = await StartAsync();
        var rider = await NewMemberAsync(api, "Ada");
        var other = await NewMemberAsync(api, "Grace");
        (await SaveAsync(rider.Client, Setup(goal: TrainingGoals.Faster, hours: 9))).EnsureSuccessStatusCode();

        var theirs = await PlanAsync(other.Client);
        Assert.False(theirs.On);
        Assert.Null(theirs.Goal);
        Assert.Empty(theirs.Days);
        Assert.Equal(HttpStatusCode.NotFound, (await other.Client.DeleteAsync("/api/v1/training/plan", Ct)).StatusCode);

        // Their own save is their own plan.
        (await SaveAsync(other.Client, Setup(goal: TrainingGoals.Aerobic, hours: 3))).EnsureSuccessStatusCode();
        var mine = await PlanAsync(rider.Client);
        Assert.True(mine.On);
        Assert.Equal(TrainingGoals.Faster, mine.Goal);
        Assert.Equal(9, mine.HoursPerWeek);
    }

    private static async Task AddSessionAsync(TestApi api, Guid userId, DateOnly date)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.TrainingSessions.Add(new TrainingSession
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            LocalDate = date,
            Recipe = "R05",
            BlockPercents = [88],
            State = TrainingSessionStates.Planned,
            CreatedAt = Now,
        });
        await db.SaveChangesAsync(Ct);
    }
}
