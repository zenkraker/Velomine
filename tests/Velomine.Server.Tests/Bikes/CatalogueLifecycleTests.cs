using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

/// <summary>The publisher's list is complete every hour: parts change, retire and come back.</summary>
public sealed class CatalogueLifecycleTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<T> WithDbAsync<T>(TestApi api, Func<VelomineDbContext, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(scope.ServiceProvider.GetRequiredService<VelomineDbContext>());
    }

    private static Task<bool> ApplyAsync(TestApi api, params CatalogueEntry[] parts) =>
        WithDbAsync(api, async db =>
        {
            var applied = await CatalogueSync.ApplyAsync(db, new CatalogueFeed(parts), Ct);
            await db.SaveChangesAsync(Ct);
            return applied;
        });

    [Fact]
    public async Task CatalogueSync_ShouldUpdateThePart_WhenThePublisherChangesItsName()
    {
        await using var api = await TestApi.StartAsync(postgres);
        await ApplyAsync(api, new CatalogueEntry("chain", "Shimano", "Ultegra original", "CN-M8100", null));

        await ApplyAsync(api, new CatalogueEntry("chain", "Shimano", "Ultegra renamed", "CN-M8100", null));

        var part = await WithDbAsync(api, db => db.Parts.AsNoTracking().SingleAsync(Ct));
        Assert.Equal("Ultegra renamed", part.Model);
        Assert.Equal("active", part.Status);
    }

    [Fact]
    public async Task CatalogueSync_ShouldReactivateThePart_WhenThePublisherListsItAgain()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var chain = new CatalogueEntry("chain", "Shimano", "Ultegra", "CN-M8100", null);
        await ApplyAsync(api, chain);
        await ApplyAsync(api, new CatalogueEntry("cassette", "Shimano", "105", "CS-R7000", null));

        Assert.Equal("retired", (await WithDbAsync(api, db => db.Parts.AsNoTracking().SingleAsync(p => p.Mpn == "CN-M8100", Ct))).Status);

        await ApplyAsync(api, chain);

        var back = await WithDbAsync(api, db => db.Parts.AsNoTracking().SingleAsync(p => p.Mpn == "CN-M8100", Ct));
        Assert.Equal("active", back.Status);
        Assert.Equal(2, await WithDbAsync(api, db => db.Parts.CountAsync(Ct))); // one row, not a second copy
    }

    [Fact]
    public async Task Contributions_ShouldNotBeSentAgain_WhenTheBackOffHasNotRunOut()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var member = await api.NewMemberAsync();
        var bike = await (await member.Client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct))
            .Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        await member.Client.PostAsJsonAsync($"/api/v1/bikes/{bike!.Bike.Id}/components", new CreateComponentRequest
        {
            Type = "chain",
            Brand = "Shimano",
            Model = "Ultegra CN-M8100",
            Mpn = "CN-M8100",
            InstalledOn = new DateOnly(2026, 1, 1),
        }, Ct);

        var options = new CatalogueOptions { ContributeUrl = "https://catalogue.test/v1/contributions", ContributionKey = "key" };
        var down = new CountingHandler(System.Net.HttpStatusCode.ServiceUnavailable);
        var clock = new FixedTime(DateTimeOffset.UtcNow);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await ContributionPush.RunAsync(db, new HttpClient(down), options, clock, null, Ct);
        }

        var pushedAgain = new CountingHandler(System.Net.HttpStatusCode.OK);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var sent = await ContributionPush.RunAsync(db, new HttpClient(pushedAgain), options, clock, null, Ct);

            Assert.Equal(0, sent);
        }

        Assert.Equal(0, pushedAgain.Calls);
    }

    private sealed class CountingHandler(System.Net.HttpStatusCode status) : HttpMessageHandler
    {
        public int Calls { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Calls++;
            await request.Content!.ReadAsStringAsync(ct);
            return new HttpResponseMessage(status) { Content = new StringContent("""{"accepted":[],"rejected":[]}""") };
        }
    }
}
