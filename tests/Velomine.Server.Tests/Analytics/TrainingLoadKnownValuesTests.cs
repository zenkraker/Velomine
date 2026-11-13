using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// Fitness, fatigue and form against hand-worked numbers, and the readiness score against the factors it sums.
/// Fatigue decays with a 7-day time constant and fitness with a 42-day one, so one 100-TSS ride today is
/// 100 x (1 - e^(-1/7)) = 63.2 for both, and form is their difference, 0.0.
/// </summary>
public sealed class TrainingLoadKnownValuesTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api, int? ftpW = null)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        if (ftpW is { } ftp) (await client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(ftp), Ct)).EnsureSuccessStatusCode();
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    private static async Task<T> InDbAsync<T>(TestApi api, Func<VelomineDbContext, Task<T>> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await work(scope.ServiceProvider.GetRequiredService<VelomineDbContext>());
    }

    [Fact]
    public async Task GetTraining_ShouldReachThirtyNineFitnessAndNinetyFiveFatigue_WhenEveryDayWasAHundredTss()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddDailyRidesAsync(api, id, days: 21, tss: 100);

        var training = await member.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct);

        // 21 days of 100 TSS: fitness (42-day constant) 39.3, fatigue (7-day constant) 95.0, form -55.7. Hand-worked
        // by iterating the two one-pole filters from a cold start 48 days back.
        var today = training!.Days[^1];
        Assert.Equal(39.3, today.Fitness);
        Assert.Equal(95.0, today.Fatigue);
        Assert.Equal(-55.7, today.Form);
    }

    [Fact]
    public async Task GetTraining_ShouldDecayFatigueFasterThanFitness_WhenTheNextDayIsRest()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        // Twenty days ending today: the ride that would have been today's is missing, so today is a rest day.
        await AddDailyRidesAsync(api, id, days: 21, tss: 100, skipToday: true);

        var training = await member.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=7", Ct);

        // Fitness fell 39.3 -> 37.0, fatigue fell 95.0 -> 81.7: the same day costs fatigue far more than fitness.
        var today = training!.Days[^1];
        Assert.Equal(37.0, today.Fitness);
        Assert.Equal(81.7, today.Fatigue);
        Assert.Equal(-44.7, today.Form);
    }

    [Fact]
    public async Task GetReadiness_ShouldBeRest_WhenTheMemberHasRiddenHardEveryDay()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddDailyRidesAsync(api, id, days: 21, tss: 100);

        var readiness = await member.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);

        // Form -55.7 gives -25 + 45 x clamp((-55.7 + 30) / 50, 0, 1) = -25; fitness a week ago was 28.3, so the ramp
        // is 39.3 - 28.3 = 11 and costs the cap of -10; the last two days are 200 TSS, not over 200, so 0.
        // 50 - 25 - 10 = 15, the rest band.
        Assert.Equal(15, readiness!.Score);
        Assert.Equal("rest", readiness.Band);
        Assert.Equal(-25.0, Assert.Single(readiness.Factors, f => f.Key == "form").Effect);
        Assert.Equal(-10.0, Assert.Single(readiness.Factors, f => f.Key == "ramp").Effect);
    }

    [Fact]
    public async Task GetReadiness_ShouldAddTheWellbeingAndRpe_WhenTheMemberCheckedInAndRatedTheRide()
    {
        await using var api = await StartAsync();
        var (member, id) = await NewMemberAsync(api);
        await AddDailyRidesAsync(api, id, days: 21, tss: 100);
        var ride = await member.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?limit=1", Ct);
        await member.PostAsJsonAsync("/api/v1/wellbeing/consent", new WellbeingConsentRequest(true), Ct);
        // Mood 4, motivation 5, fatigue 2, soreness 2, stress 2: (4 + 5 + 4 + 4 + 4) / 5 = 4.2, so (4.2 - 3) x 10 = 12.
        await member.PutAsJsonAsync("/api/v1/wellbeing/check-ins/today",
            new SaveCheckInRequest { Fatigue = 2, Soreness = 2, Mood = 4, Stress = 2, Motivation = 5 }, Ct);
        // An RPE of 4 or less reads as feeling fresh: +4.
        await member.PutAsJsonAsync($"/api/v1/rides/{ride!.Rides[0].Id}/feel",
            new SaveRideFeelRequest { Id = ride.Rides[0].Id, Rpe = 4 }, Ct);

        var readiness = await member.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);

        var wellbeing = Assert.Single(readiness!.Factors, f => f.Key == "wellbeing");
        var rpe = Assert.Single(readiness.Factors, f => f.Key == "rpe");
        Assert.Equal(4.2, wellbeing.Value);
        Assert.Equal(12.0, wellbeing.Effect);
        Assert.Equal(4.0, rpe.Effect);
        Assert.True(readiness.HasWellbeing);
        // The score is 50 plus every factor's effect, clamped to 0..100: 15 + 12 + 4 = 31.
        Assert.Equal(31, readiness.Score);
    }

    /// <summary>
    /// One <paramref name="tss"/> ride a day for <paramref name="days"/> days, the last of them <paramref name="skipToday"/>
    /// days back from today (4 November 2026).
    /// </summary>
    private static Task AddDailyRidesAsync(TestApi api, Guid userId, int days, double tss, bool skipToday = false) =>
        InDbAsync(api, async db =>
        {
            for (var back = days - 1; back >= (skipToday ? 1 : 0); back--)
                db.Rides.Add(ReadyRide(userId, new DateTimeOffset(2026, 11, 4, 7, 0, 0, TimeSpan.Zero).AddDays(-back), tss));
            await db.SaveChangesAsync(Ct);
            return 0;
        });

    /// <summary>A finished ride, as the reader would have stored it.</summary>
    private static Ride ReadyRide(Guid userId, DateTimeOffset start, double tss) => new()
    {
        Id = Guid.CreateVersion7(),
        UserId = userId,
        Status = RideStatus.Ready,
        FileName = "ride.fit",
        FileSha256 = Guid.NewGuid().ToString("N"),
        DedupKey = Guid.NewGuid().ToString("N"),
        UploadedAt = start,
        StartTime = start,
        DistanceM = 40_000,
        MovingS = 3600,
        ElevationGainM = 100,
        Tss = tss,
        Trimp = tss,
    };
}
