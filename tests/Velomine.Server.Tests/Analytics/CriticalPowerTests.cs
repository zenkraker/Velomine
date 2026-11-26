using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// Critical power and W′ from the bests of 2, 5, 10 and 20 minutes (Monod &amp; Scherrer 1965), on the model
/// P(t) = CP + W′ / t fitted by least squares on 1/t. A fit outside the believable ranges is not shown at all.
/// </summary>
public sealed class CriticalPowerTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static readonly DateTimeOffset Now = new(2026, 11, 17, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task<HttpResponseMessage> SetFtpAsync(HttpClient client, int watts) =>
        client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(watts), Ct);

    /// <summary>A ready ride a day ago whose stored bests are the given (duration, watts) pairs.</summary>
    private static async Task AddBestsAsync(TestApi api, Guid userId, params (int Seconds, int Watts)[] bests)
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
        });
        foreach (var (seconds, watts) in bests)
            db.RidePowerBests.Add(new RidePowerBest { RideId = rideId, DurationS = seconds, Watts = watts });
        await db.SaveChangesAsync(Ct);
    }

    /// <summary>The bests the model CP 250 W, W′ 20,000 J gives at 2, 5, 10 and 20 minutes, as a ride stores them.</summary>
    private static (int, int)[] ModelBests() => [(1, 400), (120, 417), (300, 317), (600, 283), (1200, 267)];

    private static async Task<PowerCurveResponse> CurveAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<PowerCurveResponse>("/api/v1/analytics/power-curve?days=90", Ct))!;

    [Fact]
    public async Task CriticalPower_ShouldRecoverTheModel_WhenTheBestsFollowIt()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBestsAsync(api, member.Id, ModelBests());

        var cp = (await CurveAsync(member.Client)).CriticalPower;

        Assert.NotNull(cp);
        Assert.InRange(cp.CpW, 249, 251);
        Assert.InRange(cp.WPrimeJ, 19_700, 20_300);
        Assert.True(cp.R2 >= 0.999);
        Assert.Equal(400, cp.PeakW);
        Assert.Equal([120, 300, 600, 1200], cp.Durations);
    }

    [Fact]
    public async Task CriticalPower_ShouldUseThreePoints_WhenOneDurationIsMissing()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBestsAsync(api, member.Id, [.. ModelBests().Where(b => b.Item1 != 1200)]);

        var cp = (await CurveAsync(member.Client)).CriticalPower;

        Assert.NotNull(cp);
        Assert.InRange(cp.CpW, 248, 252);
        Assert.Equal([120, 300, 600], cp.Durations);
    }

    [Fact]
    public async Task CriticalPower_ShouldBeNull_WhenOnlyTwoDurationsExist()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBestsAsync(api, member.Id, (1, 400), (120, 417), (300, 317));

        Assert.Null((await CurveAsync(member.Client)).CriticalPower);
    }

    [Fact]
    public async Task CriticalPower_ShouldBeNull_WhenTheFitIsPoor()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddBestsAsync(api, member.Id, (120, 300), (300, 310), (600, 200), (1200, 290));

        Assert.Null((await CurveAsync(member.Client)).CriticalPower);
    }

    [Fact]
    public async Task CriticalPower_ShouldBeNull_WhenWPrimeIsOutOfRange()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A perfect line with CP 250 W and only 2,000 J of W′: below the 3,000 J floor.
        await AddBestsAsync(api, member.Id, (120, 267), (300, 257), (600, 253), (1200, 252));

        Assert.Null((await CurveAsync(member.Client)).CriticalPower);
    }

    [Fact]
    public async Task CoachPowerCurve_ShouldIncludeCriticalPower_WhenTheAnalyticsGrantExists()
    {
        await using var api = await StartAsync();
        var coachEmail = TestApi.NewEmail();
        (await api.RegisterAsync(coachEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(coachEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, coachEmail);

        var athlete = await api.NewMemberAsync("Athlete Luca");
        (await athlete.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        await SetFtpAsync(athlete.Client, 250);
        await AddBestsAsync(api, athlete.Id, ModelBests());
        (await athlete.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();

        var curve = await coach.GetFromJsonAsync<PowerCurveResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/power-curve?days=90", Ct);

        Assert.NotNull(curve!.CriticalPower);
        Assert.InRange(curve.CriticalPower.CpW, 249, 251);
        Assert.Equal(400, curve.CriticalPower.PeakW);
        Assert.Equal([120, 300, 600, 1200], curve.CriticalPower.Durations);
    }

    [Fact]
    public async Task CoachPowerCurve_ShouldNotBeVisible_WhenRequestComesFromAnotherClub()
    {
        await using var api = await StartAsync();
        var coachEmail = TestApi.NewEmail();
        (await api.RegisterAsync(coachEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(coachEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, coachEmail);

        var athlete = await api.NewMemberAsync("Athlete Luca");
        (await athlete.Client.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        await AddBestsAsync(api, athlete.Id, ModelBests());
        (await athlete.Client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();

        // A coach of another club, asking for this athlete through their own club, is answered as if there were none.
        var otherEmail = TestApi.NewEmail();
        (await api.RegisterAsync(otherEmail, name: "Other Coach")).EnsureSuccessStatusCode();
        var other = await api.SignedInClientAsync(otherEmail, TestApi.MemberPassword);

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await other.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athlete.Id}/power-curve", Ct)).StatusCode);
    }
}
