using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// Foster's monotony and strain over the last seven days: how alike the days are, and what the week cost compared
/// with the weeks before it. Worked out from the effort scores on read, never stored.
/// </summary>
public sealed class TrainingStrainTests
{
    private static readonly DateOnly End = new(2026, 11, 4);

    /// <summary>The window ending on <see cref="End"/>, with one load per day in order.</summary>
    private static StrainWindow Compute(params double[] dailyLoads)
    {
        var from = End.AddDays(-(TrainingStrain.WindowDays - 1));
        var loads = new Dictionary<DateOnly, double>();
        for (var i = 0; i < dailyLoads.Length; i++) loads[from.AddDays(i)] = dailyLoads[i];
        return TrainingStrain.Compute(End, loads);
    }

    [Fact]
    public void Monotony_ShouldBe1Point15_WhenHardAndRestDaysAlternate()
    {
        var strain = Compute(100, 0, 100, 0, 100, 0, 100);

        // Mean 57.14, population deviation 49.49, so the monotony is 1.15 and the week's load of 400 costs 460.0.
        Assert.Equal(1.15, strain.Monotony);
        Assert.Equal(460.0, strain.Strain);
        Assert.False(strain.Monotonous);
    }

    [Fact]
    public void Monotony_ShouldWarn_WhenSixEqualDaysAndOneRest()
    {
        var strain = Compute(60, 60, 60, 60, 60, 60, 0);

        Assert.Equal(2.45, strain.Monotony);
        Assert.Equal(882.0, strain.Strain);
        Assert.True(strain.Monotonous);
    }

    [Fact]
    public void Monotony_ShouldBeCappedAt7_WhenEveryDayIsTheSame()
    {
        var strain = Compute(50, 50, 50, 50, 50, 50, 50);

        Assert.Equal(7.0, strain.Monotony);
        Assert.Equal(2450.0, strain.Strain);
        Assert.True(strain.Monotonous);
    }

    [Fact]
    public void Monotony_ShouldNeverBeInfinite_WhenEveryDayIsEqual()
    {
        // The deviation is 0, so the division never happens.
        var strain = Compute(30, 30, 30, 30, 30, 30, 30);

        Assert.NotNull(strain.Monotony);
        Assert.True(double.IsFinite(strain.Monotony!.Value));
        Assert.Equal(7.0, strain.Monotony);
    }

    [Fact]
    public void Monotony_ShouldBeNone_WhenTheWeekHasNoLoad()
    {
        var strain = Compute(0, 0, 0, 0, 0, 0, 0);

        Assert.Null(strain.Monotony);
        Assert.Null(strain.Strain);
        Assert.False(strain.Monotonous);
        Assert.False(strain.HeavyWeek);
    }

    [Fact]
    public void Monotony_ShouldBe1Point01_WhenTheWeekIsVaried()
    {
        var strain = Compute(120, 30, 0, 90, 40, 0, 200);

        Assert.Equal(1.01, strain.Monotony);
        Assert.Equal(484.8, strain.Strain);
    }

    [Fact]
    public void HeavyWeek_ShouldBeFlagged_WhenStrainIsAboveOneAndAHalfTimesUsual()
    {
        var from = End.AddDays(-(TrainingStrain.WindowDays - 1));
        var loads = new Dictionary<DateOnly, double>();
        // Four earlier weeks alternating hard and rest days: 460.0 each.
        for (var block = 1; block <= TrainingStrain.BlocksNeeded; block++)
        {
            var start = from.AddDays(-TrainingStrain.WindowDays * block);
            for (var i = 0; i < TrainingStrain.WindowDays; i++) loads[start.AddDays(i)] = i % 2 == 0 ? 100 : 0;
        }
        // This week is the same every day: 700 × 7.0 = 4900.0, far above 1.5 × 460.
        for (var i = 0; i < TrainingStrain.WindowDays; i++) loads[from.AddDays(i)] = 100;

        var strain = TrainingStrain.Compute(End, loads);

        Assert.Equal(460.0, strain.Usual);
        Assert.Equal(4900.0, strain.Strain);
        Assert.True(strain.HeavyWeek);
    }

    [Fact]
    public void HeavyWeek_ShouldNotBeFlagged_WhenThereAreFewerThanFourWeeks()
    {
        var from = End.AddDays(-(TrainingStrain.WindowDays - 1));
        var loads = new Dictionary<DateOnly, double>();
        for (var block = 1; block < TrainingStrain.BlocksNeeded; block++)
        {
            var start = from.AddDays(-TrainingStrain.WindowDays * block);
            for (var i = 0; i < TrainingStrain.WindowDays; i++) loads[start.AddDays(i)] = i % 2 == 0 ? 100 : 0;
        }
        for (var i = 0; i < TrainingStrain.WindowDays; i++) loads[from.AddDays(i)] = 100;

        var strain = TrainingStrain.Compute(End, loads);

        Assert.Null(strain.Usual);
        Assert.False(strain.HeavyWeek);
    }
}

/// <summary>
/// The same numbers on the training endpoint: which seven days the window covers, what a ride filter does, and that
/// the range reaches far enough back for the eight blocks before the week.
/// </summary>
public sealed class TrainingStrainRangeTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    /// <summary>A ready ride saved straight into the database, as a first read leaves it.</summary>
    private static async Task AddRideAsync(
        TestApi api,
        Guid userId,
        string startUtc,
        double? tss = null,
        double? hrTss = null,
        int? offsetMinutes = null,
        string? discipline = null,
        RideStatus status = RideStatus.Ready)
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
            MovingS = 3600,
            DistanceM = 40_000,
            Tss = tss,
            HrTss = hrTss,
            Discipline = discipline,
        });
        await db.SaveChangesAsync(Ct);
    }

    private static async Task<TrainingResponse> TrainingAsync(HttpClient client, string query = "days=7") =>
        (await client.GetFromJsonAsync<TrainingResponse>($"/api/v1/analytics/training?{query}", Ct))!;

    /// <summary>Seven days at the same load, ending on <paramref name="lastDayUtc"/>.</summary>
    private static async Task WeekAsync(TestApi api, Guid userId, DateOnly lastDayUtc, double tss)
    {
        for (var i = 0; i < TrainingStrain.WindowDays; i++)
            await AddRideAsync(api, userId, $"{lastDayUtc.AddDays(-i):yyyy-MM-dd}T07:00:00", tss: tss);
    }

    [Fact]
    public async Task Monotony_ShouldEndToday_WhenARideIsReady()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await WeekAsync(api, member.Id, new DateOnly(2026, 11, 4), 50);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(new DateOnly(2026, 10, 29), training.MonotonyFrom);
        Assert.Equal(new DateOnly(2026, 11, 4), training.MonotonyTo);
        Assert.Equal(7.0, training.Monotony);
        Assert.True(training.Monotonous);
    }

    [Fact]
    public async Task Monotony_ShouldEndYesterday_WhenThereIsNoRideToday()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await WeekAsync(api, member.Id, new DateOnly(2026, 11, 3), 50);

        var training = await TrainingAsync(member.Client);

        // The week that ended yesterday is the window; today is not in it yet.
        Assert.Equal(new DateOnly(2026, 10, 28), training.MonotonyFrom);
        Assert.Equal(new DateOnly(2026, 11, 3), training.MonotonyTo);
        Assert.Equal(7.0, training.Monotony);
        Assert.Equal(0, training.Days[^1].Load);
    }

    [Fact]
    public async Task Monotony_ShouldEndYesterday_WhenTodaysOnlyRideIsStillProcessing()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await WeekAsync(api, member.Id, new DateOnly(2026, 11, 3), 50);
        await AddRideAsync(api, member.Id, "2026-11-04T07:00:00", tss: 50, status: RideStatus.Processing);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(new DateOnly(2026, 11, 3), training.MonotonyTo);
        Assert.Equal(0, training.Days[^1].Load);
    }

    [Fact]
    public async Task Monotony_ShouldUseTheMembersLocalDate_WhenTheirTimeZoneIsAheadOfUtc()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // 01:00 on 5 November in Auckland: a ride just after local midnight counts on the new local day.
        (await member.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, null, null, "Pacific/Auckland", "monday"),
            Ct)).EnsureSuccessStatusCode();
        for (var day = 0; day < 6; day++)
        {
            // 06:00 local is 17:00 UTC the day before at +13.
            var local = new DateOnly(2026, 10, 30).AddDays(day);
            await AddRideAsync(api, member.Id, $"{local.AddDays(-1):yyyy-MM-dd}T17:00:00", tss: 50, offsetMinutes: 780);
        }
        await AddRideAsync(api, member.Id, "2026-11-04T11:30:00", tss: 50, offsetMinutes: 780);

        var training = await TrainingAsync(member.Client);

        Assert.Equal(new DateOnly(2026, 11, 5), training.MonotonyTo);
        Assert.Equal(new DateOnly(2026, 11, 5), training.Days[^1].Date);
        Assert.Equal(50, training.Days[^1].Load);
        Assert.Equal(7.0, training.Monotony);
    }

    [Fact]
    public async Task Training_ShouldHaveNoMonotony_WhenAFilterIsSet()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await WeekAsync(api, member.Id, new DateOnly(2026, 11, 4), 50);

        var filtered = await TrainingAsync(member.Client, "days=7&discipline=road");
        var all = await TrainingAsync(member.Client);

        Assert.NotNull(all.Monotony);
        Assert.Null(filtered.Monotony);
        Assert.Null(filtered.Strain);
        Assert.Null(filtered.StrainUsual);
        Assert.False(filtered.Monotonous);
        Assert.False(filtered.HeavyWeek);
        Assert.Null(filtered.MonotonyFrom);
        Assert.Null(filtered.MonotonyTo);
    }

    [Fact]
    public async Task HeavyWeek_ShouldNeedSixtyThreeDays_WhenTheRangeIsShort()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // Four of the eight blocks before the window: the oldest two reach past the 42-day warm-up.
        foreach (var start in new[]
                 {
                     new DateOnly(2026, 9, 2), new DateOnly(2026, 9, 9),
                     new DateOnly(2026, 9, 16), new DateOnly(2026, 9, 23),
                 })
        {
            for (var i = 0; i < TrainingStrain.WindowDays; i += 2)
                await AddRideAsync(api, member.Id, $"{start.AddDays(i):yyyy-MM-dd}T07:00:00", tss: 100);
        }
        // A heavy week, with no ride today so the window ends yesterday.
        await WeekAsync(api, member.Id, new DateOnly(2026, 11, 3), 100);

        var training = await TrainingAsync(member.Client, "days=7");

        Assert.Equal(new DateOnly(2026, 11, 3), training.MonotonyTo);
        Assert.Equal(460.0, training.StrainUsual);
        Assert.Equal(4900.0, training.Strain);
        Assert.True(training.HeavyWeek);
    }

    [Fact]
    public async Task CoachTraining_ShouldCarryMonotony_WhenTheAnalyticsGrantExists()
    {
        await using var api = await StartAsync();
        var coach = await api.NewMemberAsync();
        var club = await TestClubs.CreateAsync(api, coach);
        var rider = await api.NewMemberAsync();
        (await rider.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        (await rider.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();
        await WeekAsync(api, rider.Id, new DateOnly(2026, 11, 4), 60);

        var own = await TrainingAsync(rider.Client);
        var shown = await coach.Client.GetFromJsonAsync<TrainingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{rider.Id}/training?days=7", Ct);

        Assert.Equal(own.Monotony, shown!.Monotony);
        Assert.Equal(own.Strain, shown.Strain);
        Assert.Equal(own.StrainUsual, shown.StrainUsual);
        Assert.True(shown.Monotonous);
    }
}
