using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Analytics;

/// <summary>
/// The rider card: every number the member has, with where it came from, worked out on read from the rides, the
/// power bests, the profile and the calendar. Owner only, and estimated watts feed no row.
/// </summary>
public sealed class RiderCardTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Wednesday 4 November 2026, 12:00 UTC.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 4, 12, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static Task SetFtpAsync(HttpClient client, int watts) =>
        client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(watts), Ct);

    private static Task<HttpResponseMessage> SetRiderAsync(HttpClient client, int ftpW, double weightKg, int birthYear) =>
        client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", ftpW, weightKg, birthYear, null, "monday"),
            Ct);

    /// <summary>A ready ride saved straight into the database, as a first read leaves it.</summary>
    private static async Task<Guid> AddRideAsync(
        TestApi api,
        Guid userId,
        string startUtc,
        double km = 40,
        double hours = 1,
        double climbM = 300,
        double? tss = 60,
        bool steady = false,
        double? efficiencyFactor = null,
        int? estimatedAveragePowerW = null)
    {
        var ride = new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Status = RideStatus.Ready,
            FileSha256 = Guid.NewGuid().ToString("N"),
            FileName = "ride.fit",
            UploadedAt = Now,
            StartTime = DateTimeOffset.Parse(startUtc + "Z"),
            DistanceM = km * 1000,
            MovingS = hours * 3600,
            ElevationGainM = climbM,
            Tss = tss,
            Steady = steady ? true : null,
            EfficiencyFactor = efficiencyFactor,
            EstimatedAvgPowerW = estimatedAveragePowerW,
        };
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Rides.Add(ride);
        await db.SaveChangesAsync(Ct);
        return ride.Id;
    }

    private static async Task AddBestsAsync(TestApi api, Guid rideId, params (int Seconds, int Watts)[] bests)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        foreach (var (seconds, watts) in bests)
            db.RidePowerBests.Add(new RidePowerBest { RideId = rideId, DurationS = seconds, Watts = watts });
        await db.SaveChangesAsync(Ct);
    }

    private static async Task AddEventAsync(TestApi api, Guid userId, string name, DateOnly date)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        db.Events.Add(new TrainingEvent
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Name = name,
            Date = date,
            Kind = TrainingEventKinds.Race,
            CreatedAt = Now,
        });
        await db.SaveChangesAsync(Ct);
    }

    private static async Task<RiderCardResponse> CardAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<RiderCardResponse>("/api/v1/analytics/rider-card", Ct))!;

    [Fact]
    public async Task RiderCard_ShouldShowEveryNumberWithItsSource_WhenTheRiderHasThem()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // 250 W at 70 kg is 3.6 W/kg; born 1996, the maximum is Tanaka's estimate of 187.
        (await SetRiderAsync(member.Client, 250, 70, 1996)).EnsureSuccessStatusCode();
        (await member.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/heart-rate/threshold", new SetHeartRateRequest(165), Ct))
            .EnsureSuccessStatusCode();
        // The CP 250 W, W′ 20,000 J model's bests, plus the 5 s and 1 min efforts the card lists.
        var rideId = await AddRideAsync(api, member.Id, "2026-11-03T07:00:00", steady: true, efficiencyFactor: 1.62);
        await AddBestsAsync(api, rideId, (1, 900), (5, 900), (60, 450), (120, 417), (300, 317), (600, 283), (1200, 267));
        await AddEventAsync(api, member.Id, "Giro delle Langhe", new DateOnly(2026, 11, 8));

        var card = await CardAsync(member.Client);

        Assert.Equal(250, card.FtpW);
        Assert.Equal(70, card.WeightKg);
        Assert.Equal(3.6, card.WattsPerKg);
        Assert.Equal("manual", card.FtpSource);
        Assert.NotNull(card.FtpSetAt);
        Assert.Equal(187, card.MaxHeartRate);
        Assert.Equal("estimate", card.MaxHeartRateSource);
        Assert.Equal(165, card.ThresholdHeartRate);
        Assert.Equal("manual", card.ThresholdHeartRateSource);
        Assert.InRange(card.CriticalPowerW!.Value, 249, 251);
        Assert.InRange(card.WPrimeJ!.Value, 19_700, 20_300);
        Assert.Equal(900, card.PeakPowerW);
        Assert.Equal([5, 60, 300, 1200], card.Bests.Select(b => b.Seconds));
        Assert.Equal([900, 450, 317, 267], card.Bests.Select(b => b.Watts));
        Assert.All(card.Bests, best => Assert.Equal(rideId, best.RideId));
        Assert.All(card.Bests, best => Assert.Equal(new DateOnly(2026, 11, 3), best.Date));
        var week = Assert.Single(card.Efficiency);
        Assert.Equal(1.62, week.EfficiencyFactor);
        Assert.Equal(1, card.Rides);
        Assert.Equal(40_000, card.DistanceM);
        Assert.Equal(3600, card.MovingS);
        Assert.Equal(300, card.ElevationGainM);
        Assert.True(card.Fitness > 0);
        Assert.NotNull(card.Form);
        Assert.Equal("Giro delle Langhe", card.NextEvent!.Name);
    }

    [Fact]
    public async Task RiderCard_ShouldShowDashes_WhenTheRiderIsNew()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var card = await CardAsync(member.Client);

        Assert.Null(card.FtpW);
        Assert.Null(card.WattsPerKg);
        Assert.Null(card.FtpSource);
        Assert.Null(card.MaxHeartRate);
        Assert.Null(card.ThresholdHeartRate);
        Assert.Null(card.CriticalPowerW);
        Assert.Null(card.WPrimeJ);
        Assert.Null(card.PeakPowerW);
        Assert.Equal([5, 60, 300, 1200], card.Bests.Select(b => b.Seconds));
        Assert.All(card.Bests, best => Assert.Null(best.Watts));
        Assert.Empty(card.Efficiency);
        Assert.Equal(0, card.Rides);
        Assert.Equal(0, card.DistanceM);
        Assert.Null(card.NextEvent);
    }

    [Fact]
    public async Task RiderCard_ShouldNotBeVisible_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var owner = await api.NewMemberAsync();
        await SetFtpAsync(owner.Client, 250);
        await AddRideAsync(api, owner.Id, "2026-11-03T07:00:00");
        var stranger = await api.NewMemberAsync();

        var card = await CardAsync(stranger.Client);

        // The endpoint takes no user id, so a stranger's request can only ever be their own card.
        Assert.Null(card.FtpW);
        Assert.All(card.Bests, best => Assert.Null(best.RideId));
        Assert.Equal(0, card.Rides);
    }

    [Fact]
    public async Task RiderCard_ShouldNotUseEstimatedWatts_WhenARideHasOnlyEstimatedPower()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await AddRideAsync(api, member.Id, "2026-11-03T07:00:00", tss: null, estimatedAveragePowerW: 142);

        var card = await CardAsync(member.Client);

        // An estimate is shown on the ride and never becomes a best, a curve or critical power.
        Assert.All(card.Bests, best => Assert.Null(best.Watts));
        Assert.Null(card.CriticalPowerW);
        Assert.Null(card.PeakPowerW);
    }

    [Fact]
    public async Task RiderCard_ShouldShowMyNumbersOnly_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var first = await api.NewMemberAsync();
        var second = await api.NewMemberAsync();
        await SetFtpAsync(first.Client, 250);
        await SetFtpAsync(second.Client, 180);

        var firstCard = await CardAsync(first.Client);
        var secondCard = await CardAsync(second.Client);

        Assert.Equal(250, firstCard.FtpW);
        Assert.Equal(180, secondCard.FtpW);
        // Neither card carries the other member's number.
        Assert.NotEqual(firstCard.FtpW, secondCard.FtpW);
    }
}
