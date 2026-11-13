using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class PowerBestsBackfillTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null) => TestApi.StartAsync(postgres, more);

    private static async Task<Guid> NewMemberAsync(TestApi api) =>
        (await (await api.RegisterAsync(TestApi.NewEmail())).Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.Id;

    private static Ride AddRide(VelomineDbContext db, Guid userId, short?[] power)
    {
        var ride = new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Status = RideStatus.Ready,
            UploadedAt = DateTimeOffset.UtcNow,
            DedupKey = $"test-{Guid.NewGuid():N}",
        };
        ride.Streams = new RideStreams
        {
            RideId = ride.Id,
            Time = [0, 1, 2],
            Power = power,
        };
        db.Rides.Add(ride);
        return ride;
    }

    [Fact]
    public async Task PowerBestsBackfill_ShouldProcessEveryRide_WhenThereAreMoreThanOneBatch()
    {
        await using var api = await StartAsync();
        var userId = await NewMemberAsync(api);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            for (var i = 0; i < 51; i++) AddRide(db, userId, [100, 200, 300]);
            await db.SaveChangesAsync(Ct);
        }

        await api.Services.GetRequiredService<PowerBestsBackfill>().RunAsync(Ct);

        await using var check = api.Services.CreateAsyncScope();
        var checkDb = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(0, await checkDb.Rides.CountAsync(r => r.Status == RideStatus.Ready && r.PowerBestsBackfilledAt == null, Ct));
        Assert.Equal(51, await checkDb.Rides.CountAsync(r => r.PowerBestsBackfilledAt != null, Ct));
        Assert.True(await checkDb.RidePowerBests.AnyAsync(Ct));
    }

    [Fact]
    public async Task PowerBestsBackfill_ShouldMarkAndFinish_WhenThePowerIsAllZeroes()
    {
        await using var api = await StartAsync();
        var userId = await NewMemberAsync(api);
        Guid rideId;
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            rideId = AddRide(db, userId, [0, 0, 0]).Id;
            await db.SaveChangesAsync(Ct);
        }

        var backfill = api.Services.GetRequiredService<PowerBestsBackfill>();
        await backfill.RunAsync(Ct);
        await backfill.RunAsync(Ct); // must not select the zero-power ride forever

        await using var check = api.Services.CreateAsyncScope();
        var checkDb = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.NotNull((await checkDb.Rides.SingleAsync(r => r.Id == rideId, Ct)).PowerBestsBackfilledAt);
        Assert.False(await checkDb.RidePowerBests.AnyAsync(b => b.RideId == rideId, Ct));
    }

    [Fact]
    public async Task PowerBestsBackfill_ShouldNotDuplicateRows_WhenItRunsAgain()
    {
        await using var api = await StartAsync();
        var userId = await NewMemberAsync(api);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            AddRide(db, userId, [100, 200, 300]);
            await db.SaveChangesAsync(Ct);
        }

        var backfill = api.Services.GetRequiredService<PowerBestsBackfill>();
        await backfill.RunAsync(Ct);
        int count;
        await using (var check = api.Services.CreateAsyncScope())
            count = await check.ServiceProvider.GetRequiredService<VelomineDbContext>().RidePowerBests.CountAsync(Ct);

        await backfill.RunAsync(Ct);

        await using var after = api.Services.CreateAsyncScope();
        Assert.Equal(count, await after.ServiceProvider.GetRequiredService<VelomineDbContext>().RidePowerBests.CountAsync(Ct));
    }

    [Fact]
    public async Task PowerBestsBackfill_ShouldContinue_WhenOneRideFails()
    {
        var interceptor = new FailOnceInterceptor();
        await using var api = await StartAsync(builder => builder.ConfigureServices(
            services => services.AddSingleton<IInterceptor>(interceptor)));

        var userId = await NewMemberAsync(api);
        Guid failingId;
        Guid goodId;
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            failingId = AddRide(db, userId, [100, 200, 300]).Id;
            goodId = AddRide(db, userId, [300, 200, 100]).Id;
            await db.SaveChangesAsync(Ct);
        }
        interceptor.RideId = failingId;

        await api.Services.GetRequiredService<PowerBestsBackfill>().RunAsync(Ct);

        await using var check = api.Services.CreateAsyncScope();
        var checkDb = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.NotNull((await checkDb.Rides.SingleAsync(r => r.Id == failingId, Ct)).PowerBestsBackfilledAt);
        Assert.NotNull((await checkDb.Rides.SingleAsync(r => r.Id == goodId, Ct)).PowerBestsBackfilledAt);
        Assert.Equal(1, await checkDb.RidePowerBests.CountAsync(b => b.RideId == goodId, Ct));
        Assert.Equal(0, await checkDb.RidePowerBests.CountAsync(b => b.RideId == failingId, Ct));
    }

    private sealed class FailOnceInterceptor : SaveChangesInterceptor
    {
        public Guid RideId { get; set; }
        private bool thrown;

        public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData,
            InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            if (!thrown && eventData.Context is { } context
                && context.ChangeTracker.Entries<RidePowerBest>().Any(e => e.Entity.RideId == RideId))
            {
                thrown = true;
                throw new DbUpdateException("Test failure.");
            }

            return base.SavingChangesAsync(eventData, result, cancellationToken);
        }
    }
}
