using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

[Collection("postgres")]
public sealed class CatalogueTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(bool seed = false) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.UseSetting("Velomine:Catalogue:Seed", seed ? "true" : "false");
    });

    private static async Task<HttpClient> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return await api.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    private static async Task<Guid> AddBikeAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static async Task<PartResponse[]> SearchAsync(HttpClient client, string query, string? type = null)
    {
        var url = $"/api/v1/bikes/parts?q={Uri.EscapeDataString(query)}" + (type is null ? "" : $"&type={type}");
        return (await client.GetFromJsonAsync<SearchPartsResponse>(url, Ct))!.Parts;
    }

    private static CatalogueEntry Chain(string model = "CN-M8100") => new("chain", "Shimano", model, model, null);

    private static CatalogueFeed Feed(params CatalogueEntry[] parts) => new(parts);

    private static async Task<T> WithDbAsync<T>(TestApi api, Func<VelomineDbContext, TimeProvider, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(
            scope.ServiceProvider.GetRequiredService<VelomineDbContext>(),
            scope.ServiceProvider.GetRequiredService<TimeProvider>());
    }

    private static Task<int> ApplyAsync(TestApi api, CatalogueFeed feed) =>
        WithDbAsync(api, async (db, _) =>
        {
            var applied = await CatalogueSync.ApplyAsync(db, feed, Ct);
            await db.SaveChangesAsync(Ct);
            return applied ? 1 : 0;
        });

    [Fact]
    public async Task CatalogueSeed_ShouldLoadTheBundledParts_WhenTheClubIsEmpty()
    {
        await using var api = await StartAsync(seed: true);
        var member = await NewMemberAsync(api);

        var chains = await SearchAsync(member, "CN-M8100", "chain");
        var frontPads = await SearchAsync(member, "B01S", "front_brake_pads");
        var rearPads = await SearchAsync(member, "B01S", "rear_brake_pads");

        Assert.Single(chains);
        Assert.Equal("Shimano", chains[0].Brand);
        Assert.Single(frontPads);
        Assert.Single(rearPads);
        Assert.NotEqual(frontPads[0].Id, rearPads[0].Id); // the same pad code, two parts on the bike
    }

    [Fact]
    public async Task CatalogueSeed_ShouldNotLoadThePartsAgain_WhenTheClubAlreadyHasACatalogue()
    {
        await using var api = await StartAsync(seed: true);

        var second = await WithDbAsync(api, (db, clock) => CatalogueSeed.EnsureSeededAsync(db, clock, Ct));
        var count = await WithDbAsync(api, (db, _) => db.Parts.CountAsync(Ct));

        Assert.False(second);
        Assert.True(count > 40);
    }

    [Fact]
    public async Task CatalogueSync_ShouldAddThePublishersParts_WhenTheFeedHasThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        Assert.Equal(1, await ApplyAsync(api, Feed(Chain())));

        var part = Assert.Single(await SearchAsync(member, "CN-M8100"));
        Assert.Equal("Shimano", part.Brand);
    }

    [Fact]
    public async Task CatalogueSync_ShouldRetireAPart_WhenTheNewSnapshotLeavesItOut()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await ApplyAsync(api, Feed(Chain("CN-M8100")));
        await ApplyAsync(api, Feed(Chain("CN-M7100")));

        Assert.Empty(await SearchAsync(member, "CN-M8100"));
        Assert.Single(await SearchAsync(member, "CN-M7100"));
    }

    [Fact]
    public async Task CatalogueSync_ShouldRetireAClubEnteredPart_WhenThePublisherDoesNotListIt()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await WithDbAsync(api, async (db, clock) =>
        {
            db.Parts.Add(new Part
            {
                Id = Guid.CreateVersion7(),
                Key = PartIdentity.Key("chain", "Shimano", "Old local entry", "CN-OLD", null)!,
                Type = "chain",
                Brand = "Shimano",
                Model = "Old local entry",
                Mpn = "CN-OLD",
                Source = "local",
                CreatedAt = clock.GetUtcNow(),
            });
            await db.SaveChangesAsync(Ct);
            return true;
        });

        await ApplyAsync(api, Feed(Chain()));

        Assert.Empty(await SearchAsync(member, "CN-OLD"));
    }

    [Fact]
    public async Task CatalogueSync_ShouldNotRetireAnything_WhenTheFeedIsEmpty()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await ApplyAsync(api, Feed(Chain()));
        Assert.Equal(0, await ApplyAsync(api, Feed()));

        Assert.Single(await SearchAsync(member, "CN-M8100"));
    }

    [Fact]
    public async Task CatalogueSync_ShouldNotDuplicateAPart_WhenTheSameFeedIsAppliedTwice()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        await ApplyAsync(api, Feed(Chain()));
        await ApplyAsync(api, Feed(Chain()));

        Assert.Single(await SearchAsync(member, "CN-M8100"));
        Assert.Equal(1, await WithDbAsync(api, (db, _) => db.Parts.CountAsync(Ct)));
    }

    [Fact]
    public async Task CatalogueSync_ShouldRecordTheSync_WhenItAppliesTheFeed()
    {
        await using var api = await StartAsync();
        var source = new StubSource(Feed(Chain()));

        var applied = await WithDbAsync(api, (db, clock) =>
            CatalogueSync.RunAsync(db, source, clock, "https://catalogue.test/v1/parts", Ct));
        var meta = await WithDbAsync(api, (db, _) => db.CatalogueMeta.SingleAsync(Ct));

        Assert.True(applied);
        Assert.Equal("https://catalogue.test/v1/parts", meta.SourceUrl);
        Assert.NotNull(meta.SyncedAt);
        Assert.Equal(1, await WithDbAsync(api, (db, _) => db.Parts.CountAsync(Ct)));
    }

    [Fact]
    public async Task CatalogueSync_ShouldKeepItsParts_WhenTheSourceFails()
    {
        await using var api = await StartAsync();
        await ApplyAsync(api, Feed(Chain()));

        await Assert.ThrowsAsync<HttpRequestException>(() =>
            WithDbAsync(api, (db, clock) => CatalogueSync.RunAsync(db, new FailingSource(), clock, "https://catalogue.test", Ct)));

        var member = await NewMemberAsync(api);
        Assert.Single(await SearchAsync(member, "CN-M8100"));
    }

    [Fact]
    public async Task HttpCatalogueSource_ShouldReadTheFeed_WhenTheServerSendsOne()
    {
        const string json = """
            { "parts": [ { "type": "chain", "brand": "Shimano", "model": "CN-M8100", "mpn": "CN-M8100" } ] }
            """;
        var handler = new StubHandler(HttpStatusCode.OK, json);
        var source = new HttpCatalogueSource(
            new HttpClient(handler),
            Microsoft.Extensions.Options.Options.Create(new CatalogueOptions { Url = "https://catalogue.test/v1/parts?club=acme" }));

        var feed = await source.FetchAsync(Ct);

        Assert.NotNull(feed);
        Assert.Equal("CN-M8100", Assert.Single(feed.Parts).Mpn);
        Assert.Equal("https://catalogue.test/v1/parts?club=acme", handler.LastRequest!.RequestUri!.ToString());
    }

    private sealed class StubSource(CatalogueFeed feed) : ICatalogueSource
    {
        public Task<CatalogueFeed?> FetchAsync(CancellationToken ct) => Task.FromResult<CatalogueFeed?>(feed);
    }

    private sealed class FailingSource : ICatalogueSource
    {
        public Task<CatalogueFeed?> FetchAsync(CancellationToken ct) =>
            throw new HttpRequestException("The catalogue is down.");
    }

    private sealed class StubHandler(HttpStatusCode status, string body) : HttpMessageHandler
    {
        public HttpRequestMessage? LastRequest { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            LastRequest = request;
            return Task.FromResult(new HttpResponseMessage(status)
            {
                Content = new StringContent(body, System.Text.Encoding.UTF8, "application/json"),
            });
        }
    }
}
