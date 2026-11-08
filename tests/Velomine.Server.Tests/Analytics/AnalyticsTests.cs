using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests.Analytics;

[Collection("postgres")]
public sealed class AnalyticsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    /// <summary>Saves a finished ride straight into the database, as if it had been uploaded and read.</summary>
    private static async Task AddRideAsync(TestApi api, Guid userId, string startUtc, double km, double hours = 1, double climbM = 0,
        int? offsetMinutes = null, RideStatus status = RideStatus.Ready, double? tss = null, double? trimp = null, int? normalizedPowerW = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Status = status,
            FileSha256 = Guid.NewGuid().ToString("N"),
            FileName = "ride.fit",
            UploadedAt = Now,
            StartTime = DateTimeOffset.Parse(startUtc + "Z"),
            UtcOffsetMinutes = offsetMinutes,
            DistanceM = km * 1000,
            MovingS = hours * 3600,
            ElevationGainM = climbM,
            Tss = tss,
            Trimp = trimp,
            NormalizedPowerW = normalizedPowerW,
        });
        await db.SaveChangesAsync(Ct);
    }

    private static Task SetProfileAsync(HttpClient member, string? zone, string firstDay) =>
        member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Rider", null, null, null, zone, firstDay), Ct);

    [Fact]
    public async Task WeeklyTotals_AddUpEachWeek_OnTheMembersCalendar()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddRideAsync(api, id, "2026-11-02T07:00:00", 40, 1.5, 300);   // Monday this week
        await AddRideAsync(api, id, "2026-11-04T06:00:00", 20, 0.75, 100);  // today
        await AddRideAsync(api, id, "2026-10-28T07:00:00", 60, 2, 500);     // last week
        await AddRideAsync(api, id, "2026-11-03T07:00:00", 99, status: RideStatus.Failed); // not counted
        await AddRideAsync(api, id, "2026-11-03T07:00:00", 99, status: RideStatus.Duplicate); // not counted

        var totals = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=week&count=3", Ct);

        Assert.Equal("week", totals!.Period);
        Assert.Equal(
            [
                new PeriodTotals(new DateOnly(2026, 10, 19), new DateOnly(2026, 10, 25), 0, 0, 0, 0),
                new PeriodTotals(new DateOnly(2026, 10, 26), new DateOnly(2026, 11, 1), 1, 60_000, 7200, 500),
                new PeriodTotals(new DateOnly(2026, 11, 2), new DateOnly(2026, 11, 8), 2, 60_000, 8100, 400),
            ],
            totals.Totals);
    }

    [Fact]
    public async Task SundayWeeks_AndTheMembersTimeZone_DecideWhichWeekARideIsIn()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        // Saturday 31 October 23:30 UTC, a GPX ride with no offset: Sunday 1 November in Rome.
        await AddRideAsync(api, id, "2026-10-31T23:30:00", 30);

        var utcMonday = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=week&count=2", Ct);
        Assert.Equal([1, 0], utcMonday!.Totals.Select(t => t.Rides)); // Saturday: last week

        await SetProfileAsync(member, "Europe/Rome", "sunday");
        var romeSunday = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=week&count=2", Ct);
        Assert.Equal(new DateOnly(2026, 11, 1), romeSunday!.Totals[^1].Start);
        Assert.Equal([0, 1], romeSunday.Totals.Select(t => t.Rides)); // Sunday in Rome: this week
    }

    [Fact]
    public async Task MonthlyAndYearlyTotals_DefaultToTwelvePeriods()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddRideAsync(api, id, "2026-11-01T08:00:00", 50);
        await AddRideAsync(api, id, "2026-01-15T08:00:00", 70);
        await AddRideAsync(api, id, "2025-12-31T08:00:00", 10);

        var months = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=month", Ct);
        Assert.Equal(12, months!.Totals.Length);
        Assert.Equal(new DateOnly(2025, 12, 1), months.Totals[0].Start);
        Assert.Equal(new DateOnly(2026, 11, 30), months.Totals[^1].End);
        Assert.Equal(50_000, months.Totals[^1].DistanceM);
        Assert.Equal(70_000, months.Totals[1].DistanceM);
        Assert.Equal(10_000, months.Totals[0].DistanceM);

        var years = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=year&count=2", Ct);
        Assert.Equal([10_000, 120_000], years!.Totals.Select(t => t.DistanceM));
    }

    [Theory]
    [InlineData("period=fortnight")]
    [InlineData("period=week&count=0")]
    [InlineData("period=week&count=61")]
    public async Task InvalidTotalsRequestsAreRejected(string query)
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.BadRequest, (await member.GetAsync($"/api/v1/analytics/totals?{query}", Ct)).StatusCode);
    }

    [Fact]
    public async Task OnlyMyOwnRidesCount()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var (_, otherId) = await NewMemberAsync(api);
        await AddRideAsync(api, otherId, "2026-11-03T08:00:00", 80);

        var totals = await member.GetFromJsonAsync<TotalsResponse>("/api/v1/analytics/totals?period=week&count=1", Ct);
        Assert.Equal(0, totals!.Totals.Single().Rides);
    }

    [Fact]
    public async Task Goals_ShowProgressForTheCurrentPeriod()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddRideAsync(api, id, "2026-11-02T07:00:00", 40, 1.5, 300); // this week
        await AddRideAsync(api, id, "2026-10-28T07:00:00", 60, 2, 500);   // last week, this year

        var weekly = await CreateAsync(member, "week", "distance", 100_000);
        Assert.Equal(new DateOnly(2026, 11, 2), weekly.PeriodStart);
        Assert.Equal(new DateOnly(2026, 11, 8), weekly.PeriodEnd);
        Assert.Equal(40_000, weekly.Current);
        Assert.Equal(40, weekly.Percent);
        Assert.False(weekly.Reached);

        await CreateAsync(member, "year", "elevation", 800);
        await CreateAsync(member, "month", "rides", 3);
        await CreateAsync(member, "week", "time", 3600);

        var goals = (await member.GetFromJsonAsync<ListGoalsResponse>("/api/v1/analytics/goals", Ct))!.Goals;
        Assert.Equal(["week distance", "week time", "month rides", "year elevation"], goals.Select(g => $"{g.Period} {g.Metric}"));
        Assert.Equal([40_000, 5400, 1, 800], goals.Select(g => g.Current)); // the October ride is not in this month
        Assert.Equal([40, 150, 33, 100], goals.Select(g => g.Percent));
        Assert.Equal([false, true, false, true], goals.Select(g => g.Reached));
    }

    [Fact]
    public async Task Goals_CanBeChangedAndDeleted_ButNotDoubled()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var goal = await CreateAsync(member, "month", "distance", 500_000);

        var twice = await member.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = "month", Metric = "distance", Target = 1 }, Ct);
        Assert.Equal(HttpStatusCode.Conflict, twice.StatusCode);

        var put = await member.PutAsJsonAsync($"/api/v1/analytics/goals/{goal.Id}", new UpdateGoalRequest { Target = 800_000 }, Ct);
        Assert.Equal(800_000, (await put.Content.ReadFromJsonAsync<GoalResponse>(Ct))!.Target);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/analytics/goals/{goal.Id}", Ct)).StatusCode);
        Assert.Empty((await member.GetFromJsonAsync<ListGoalsResponse>("/api/v1/analytics/goals", Ct))!.Goals);
    }

    [Theory]
    [InlineData("day", "distance", 10)]
    [InlineData("week", "calories", 10)]
    [InlineData("week", "distance", 0)]
    [InlineData("week", "distance", 1e12)]
    public async Task InvalidGoalsAreRejected(string period, string metric, double target)
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);

        var post = await member.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = period, Metric = metric, Target = target }, Ct);
        Assert.Equal(HttpStatusCode.BadRequest, post.StatusCode);
    }

    [Fact]
    public async Task OthersCannotSeeOrChangeMyGoals()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);
        var (other, _) = await NewMemberAsync(api);
        var goal = await CreateAsync(member, "week", "distance", 100_000);

        Assert.Empty((await other.GetFromJsonAsync<ListGoalsResponse>("/api/v1/analytics/goals", Ct))!.Goals);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/v1/analytics/goals/{goal.Id}", new UpdateGoalRequest { Target = 1 }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.DeleteAsync($"/api/v1/analytics/goals/{goal.Id}", Ct)).StatusCode);
    }

    [Fact]
    public async Task Training_AddsUpLoadAndBuildsFitnessAndForm()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddRideAsync(api, id, "2026-11-03T07:00:00", 40, 1, tss: 100, trimp: 80);
        await AddRideAsync(api, id, "2026-11-04T07:00:00", 20, 0.5, tss: 50, trimp: 40);

        var training = await member.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct);

        Assert.Equal(7, training!.DayCount);
        Assert.Equal(new DateOnly(2026, 10, 29), training.From);
        Assert.Equal(new DateOnly(2026, 11, 4), training.To);
        Assert.Equal(2, training.Rides);
        Assert.Equal(150, training.Tss);
        Assert.Equal(120, training.Trimp);

        var last = training.Days[^1];
        Assert.Equal(new DateOnly(2026, 11, 4), last.Date);
        Assert.Equal(50, last.Tss);
        Assert.True(last.Fitness > 0);
        Assert.True(last.Fatigue > last.Fitness);
        Assert.Equal(last.Fitness - last.Fatigue, last.Form, 1);
    }

    [Fact]
    public async Task Training_FillsLoadForRidesReadBeforeTheProfileHadFtp()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await member.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", 250, null, null, null, "monday"), Ct);
        await AddRideAsync(api, id, "2026-11-04T07:00:00", 40, 1, normalizedPowerW: 200);

        var training = await member.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct);

        Assert.Equal(64, training!.Tss);
        Assert.Equal(64, training.Days[^1].Tss);
        Assert.True(training.Days[^1].Fitness > 0);
    }

    [Fact]
    public async Task Training_RejectsARangeLongerThanTwoYears()
    {
        await using var api = await StartAsync();
        var (member, _) = await NewMemberAsync(api);

        var response = await member.GetAsync("/api/v1/analytics/training?days=731", Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static async Task<GoalResponse> CreateAsync(HttpClient member, string period, string metric, double target)
    {
        var post = await member.PostAsJsonAsync("/api/v1/analytics/goals", new CreateGoalRequest { Period = period, Metric = metric, Target = target }, Ct);
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);
        return (await post.Content.ReadFromJsonAsync<GoalResponse>(Ct))!;
    }
}
