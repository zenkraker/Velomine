using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests;

/// <summary>
/// The FTP reminder: stale after 42 days of riding with power, higher than the estimate, or missing, and quiet
/// while the member has snoozed it. Every rule is read on the member's own calendar.
/// </summary>
public sealed class FtpReminderTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    // A fixed clock, so "42 days old" is 42 days and not 42 or 43 depending on the hour.
    private static readonly DateTimeOffset Now = new(2026, 11, 17, 12, 0, 0, TimeSpan.Zero);
    private static DateOnly Today => DateOnly.FromDateTime(Now.UtcDateTime);

    private Task<TestApi> StartAsync() => StartAsync(Now);

    private Task<TestApi> StartAsync(DateTimeOffset now) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(now)));
    });

    private static Task<HttpResponseMessage> SetFtpAsync(HttpClient client, int watts) =>
        client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(watts), Ct);

    private static async Task<FtpCheckResponse> CheckAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<FtpCheckResponse>("/api/v1/analytics/ftp-check", Ct))!;

    /// <summary>An FTP set <paramref name="ageDays"/> before today, through the history the reminder reads.</summary>
    private static Task SetFtpOnAsync(TestApi api, Guid userId, int watts, int ageDays) =>
        SetFtpAtAsync(api, userId, watts, Now.AddDays(-ageDays));

    /// <summary>An FTP set at an exact instant, through the history the reminder reads.</summary>
    private static async Task SetFtpAtAsync(TestApi api, Guid userId, int watts, DateTimeOffset setAt)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.FindAsync([userId], Ct);
        user!.FtpW = watts;
        db.FtpHistory.Add(new FtpHistory
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Watts = watts,
            SetAt = setAt,
            Source = FtpSources.Manual,
        });
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>A rider whose FTP was set at 23:30 UTC on 7 October, which is midday on 8 October in Auckland.</summary>
    private static DateTimeOffset NearMidnight => new(2026, 10, 7, 23, 30, 0, TimeSpan.Zero);

    private static DateOnly NearMidnightLocalDay => new(2026, 10, 8);

    /// <summary>A ready ride with power, a day before today.</summary>
    private static async Task AddPowerRideAsync(TestApi api, Guid userId, int normalizedPowerW)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Status = RideStatus.Ready,
            StartTime = Now.AddDays(-1),
            NormalizedPowerW = normalizedPowerW,
        });
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>A 20-minute best of <paramref name="watts"/> a day ago: the 42-day estimate is 95 % of it.</summary>
    private static async Task AddBest20Async(TestApi api, Guid userId, int watts)
    {
        var rideId = Guid.NewGuid();
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(new Ride
        {
            Id = rideId,
            UserId = userId,
            Status = RideStatus.Ready,
            StartTime = Now.AddDays(-1),
            NormalizedPowerW = watts,
        });
        db.RidePowerBests.Add(new RidePowerBest { RideId = rideId, DurationS = 1200, Watts = watts });
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task FtpCheck_ShouldSayStale_WhenTheFtpIs42DaysOldAndTheRiderRodeWithPower()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpOnAsync(api, member.Id, 250, 42);
        await AddPowerRideAsync(api, member.Id, 200);

        var check = await CheckAsync(member.Client);

        Assert.Equal(FtpReminderReasons.Stale, check.Reason);
        Assert.Equal(250, check.FtpW);
        Assert.Equal(42, check.FtpAgeDays);
    }

    [Fact]
    public async Task FtpCheck_ShouldCountDaysOnTheRidersCalendar_WhenTheFtpWasSetNearMidnight()
    {
        // A rider in Auckland (UTC+13 in November) whose FTP was set at 23:30 UTC: for them it was the next day.
        async Task<FtpCheckResponse?> CheckOnAsync(DateOnly localToday)
        {
            // Midday in Auckland, the way a rider's own day runs.
            var now = new DateTimeOffset(localToday.ToDateTime(new TimeOnly(12, 0)), TimeSpan.Zero).AddHours(-13);
            await using var api = await StartAsync(now);
            var member = await api.NewMemberAsync();
            (await member.Client.PutAsJsonAsync(
                "/api/v1/accounts/me/profile",
                new UpdateProfileRequest("Test Rider", null, null, null, "Pacific/Auckland", "monday"), Ct)).EnsureSuccessStatusCode();
            await SetFtpAtAsync(api, member.Id, 250, NearMidnight);
            await AddPowerRideAsync(api, member.Id, 200);

            return await CheckAsync(member.Client);
        }

        // 41 days on the rider's calendar, and 42 after the UTC date it was set on: the ride has not made it stale yet.
        var notYet = await CheckOnAsync(NearMidnightLocalDay.AddDays(41));
        Assert.Null(notYet!.Reason);
        Assert.Equal(41, notYet.FtpAgeDays);

        // One local day later it is 42 days old, and the reminder speaks.
        var stale = await CheckOnAsync(NearMidnightLocalDay.AddDays(42));
        Assert.Equal(FtpReminderReasons.Stale, stale!.Reason);
        Assert.Equal(42, stale.FtpAgeDays);
    }

    [Fact]
    public async Task FtpCheck_ShouldSayNothing_WhenTheFtpIs41DaysOld()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpOnAsync(api, member.Id, 250, 41);
        await AddPowerRideAsync(api, member.Id, 200);

        Assert.Null((await CheckAsync(member.Client)).Reason);
    }

    [Fact]
    public async Task FtpCheck_ShouldSayNothing_WhenTheRiderHasNoPowerRideIn28Days()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetFtpOnAsync(api, member.Id, 250, 60);

        // A ride from 29 days ago is outside the window the reminder looks at.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            db.Rides.Add(new Ride
            {
                Id = Guid.NewGuid(),
                UserId = member.Id,
                Status = RideStatus.Ready,
                StartTime = Now.AddDays(-29),
                NormalizedPowerW = 200,
            });
            await db.SaveChangesAsync(Ct);
        }

        Assert.Null((await CheckAsync(member.Client)).Reason);
    }

    [Fact]
    public async Task FtpCheck_ShouldSayEstimateHigher_WhenTheEstimateIsFivePercentAbove()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        // 95 % of 277 W is 263 W, which is 250 W + 5.2 %: above the line. 262 W (95 % of 276 W) is not.
        await SetFtpOnAsync(api, member.Id, 250, 1);
        await AddBest20Async(api, member.Id, 276);
        var low = await CheckAsync(member.Client);
        Assert.Null(low.Reason);
        Assert.Equal(262, low.EstimateW);

        await AddBest20Async(api, member.Id, 277);
        var high = await CheckAsync(member.Client);
        Assert.Equal(FtpReminderReasons.EstimateHigher, high.Reason);
        Assert.Equal(263, high.EstimateW);
        Assert.Equal("20min", high.EstimateMethod);
    }

    [Fact]
    public async Task FtpCheck_ShouldSayMissing_WhenThereIsNoFtpButAnEstimate()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBest20Async(api, member.Id, 280);

        var check = await CheckAsync(member.Client);

        Assert.Equal(FtpReminderReasons.Missing, check.Reason);
        Assert.Null(check.FtpW);
        Assert.Null(check.FtpAgeDays);
        Assert.Equal(266, check.EstimateW);
    }

    [Fact]
    public async Task FtpCheck_ShouldStaySilent_WhenSnoozed()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBest20Async(api, member.Id, 280);
        Assert.Equal(FtpReminderReasons.Missing, (await CheckAsync(member.Client)).Reason);

        Assert.Equal(HttpStatusCode.NoContent, (await member.Client.PostAsync("/api/v1/analytics/ftp-check/snooze", null, Ct)).StatusCode);

        Assert.Null((await CheckAsync(member.Client)).Reason);
    }

    [Fact]
    public async Task FtpCheck_ShouldSpeakAgain_WhenTheSnoozeHasEnded()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBest20Async(api, member.Id, 280);
        await member.Client.PostAsync("/api/v1/analytics/ftp-check/snooze", null, Ct);

        // The snooze ends the day after the one it was set to; the member's calendar says when.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var user = await db.Users.FindAsync([member.Id], Ct);
            user!.FtpReminderSnoozedUntil = Today;
            await db.SaveChangesAsync(Ct);
        }

        Assert.Equal(FtpReminderReasons.Missing, (await CheckAsync(member.Client)).Reason);
    }

    [Fact]
    public async Task SetFtp_ShouldClearTheSnooze_WhenTheFtpChanges()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await member.Client.PostAsync("/api/v1/analytics/ftp-check/snooze", null, Ct);

        Assert.Equal(HttpStatusCode.OK, (await SetFtpAsync(member.Client, 250)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var user = await db.Users.FindAsync([member.Id], Ct);
        Assert.Null(user!.FtpReminderSnoozedUntil);
    }

    [Fact]
    public async Task FtpCheck_ShouldNotBeVisible_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetFtpOnAsync(api, me.Id, 250, 42);
        await AddPowerRideAsync(api, me.Id, 200);
        Assert.Equal(FtpReminderReasons.Stale, (await CheckAsync(me.Client)).Reason);

        // The check is the caller's own: Grace has no FTP and no rides, so she is told nothing about Ada's.
        var theirs = await CheckAsync(other.Client);
        Assert.Null(theirs.Reason);
        Assert.Null(theirs.FtpW);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/analytics/ftp-check", Ct)).StatusCode);
    }
}
