using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

[Collection("postgres")]
public sealed class ContributionsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static Task<HttpClient> AdminAsync(TestApi api) =>
        api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private static async Task<Guid> AddBikeAsync(HttpClient client, string name = "Road bike")
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = name, Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static CreateComponentRequest Chain(bool custom = false) => new()
    {
        Type = "chain",
        Brand = "Shimano",
        Model = "Ultegra CN-M8100",
        Mpn = "CN-M8100",
        Custom = custom,
        InstalledOn = new DateOnly(2026, 1, 1),
    };

    private static async Task AddChainAsync(HttpClient client, Guid bikeId, bool custom = false)
    {
        (await client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", Chain(custom), Ct))
            .EnsureSuccessStatusCode();
    }

    private static async Task<T> WithDbAsync<T>(TestApi api, Func<VelomineDbContext, TimeProvider, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(
            scope.ServiceProvider.GetRequiredService<VelomineDbContext>(),
            scope.ServiceProvider.GetRequiredService<TimeProvider>());
    }

    private static async Task AddToSharedCatalogueAsync(TestApi api)
    {
        await WithDbAsync(api, async (db, clock) =>
        {
            db.Parts.Add(new Part
            {
                Id = Guid.CreateVersion7(),
                Key = PartIdentity.Key("chain", "Shimano", "Ultegra CN-M8100", "CN-M8100", null)!,
                Type = "chain",
                Brand = "Shimano",
                Model = "Ultegra CN-M8100",
                Mpn = "CN-M8100",
                Source = CatalogueSync.SharedSource,
                CreatedAt = clock.GetUtcNow(),
            });
            await db.SaveChangesAsync(Ct);
            return true;
        });
    }

    private static CatalogueOptions Options() => new()
    {
        ContributeUrl = "https://catalogue.test/v1/contributions",
        ContributionKey = "deployment-key",
    };

    [Fact]
    public async Task CatalogueContributions_ShouldQueueThePartAlone_WhenThePublisherHasNotListedIt()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        var contribution = await WithDbAsync(api, (db, _) => db.PartContributions.SingleAsync(Ct));
        var json = JsonSerializer.Serialize(
            ContributionEntry.From(new BikeComponent
            {
                Type = contribution.Type,
                Brand = contribution.Brand,
                Model = contribution.Model,
                Mpn = contribution.Mpn,
                Gtin = contribution.Gtin,
            }),
            new JsonSerializerOptions(JsonSerializerDefaults.Web));

        Assert.Equal("pending", contribution.Status);
        Assert.Equal("chain", contribution.Type);
        Assert.Equal("Shimano", contribution.Brand);
        Assert.DoesNotContain("bike", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("user", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("club", json, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CatalogueContributions_ShouldNotQueue_WhenThePartIsCustom()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member), custom: true);

        Assert.Equal(0, await WithDbAsync(api, (db, _) => db.PartContributions.CountAsync(Ct)));
    }

    [Fact]
    public async Task CatalogueContributions_ShouldNotQueue_WhenThePublisherAlreadyListsThePart()
    {
        await using var api = await StartAsync();
        await AddToSharedCatalogueAsync(api);
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        Assert.Equal(0, await WithDbAsync(api, (db, _) => db.PartContributions.CountAsync(Ct)));
    }

    [Fact]
    public async Task CatalogueContributions_ShouldQueueThePartOnce_WhenTheSamePartIsAddedTwice()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member, "One"));
        await AddChainAsync(member, await AddBikeAsync(member, "Two"));

        Assert.Equal(1, await WithDbAsync(api, (db, _) => db.PartContributions.CountAsync(Ct)));
    }

    [Fact]
    public async Task CatalogueContributions_ShouldBeSent_WhenThePublisherAcceptsThem()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        var key = "mpn:chain:shimano|CN-M8100";
        var handler = new StubHandler(HttpStatusCode.OK,
            $$"""{"accepted":["{{key}}"],"rejected":[]}""");
        var sent = await WithDbAsync(api, (db, clock) =>
            ContributionPush.RunAsync(db, new HttpClient(handler), Options(), clock, null, Ct));

        var contribution = await WithDbAsync(api, (db, _) => db.PartContributions.SingleAsync(Ct));
        Assert.Equal(1, sent);
        Assert.Equal("sent", contribution.Status);
        Assert.NotNull(contribution.SentAt);
        Assert.Equal("Bearer deployment-key", handler.LastAuthorization);
        var submission = Assert.Single(handler.LastParts!);
        Assert.Equal(key, submission.Key);
        Assert.Equal("CN-M8100", submission.Mpn);
    }

    [Fact]
    public async Task CatalogueContributions_ShouldBeRejectedAndShownToAnAdmin_WhenThePublisherRefusesThePart()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        var key = "mpn:chain:shimano|CN-M8100";
        var handler = new StubHandler(HttpStatusCode.OK,
            $$"""{"accepted":[],"rejected":[{"key":"{{key}}","reason":"Not a real part code."}]}""");
        await WithDbAsync(api, (db, clock) =>
            ContributionPush.RunAsync(db, new HttpClient(handler), Options(), clock, null, Ct));

        var contribution = await WithDbAsync(api, (db, _) => db.PartContributions.SingleAsync(Ct));
        Assert.Equal("rejected", contribution.Status);
        Assert.Equal("Not a real part code.", contribution.Reason);

        var catalogue = await (await AdminAsync(api))
            .GetFromJsonAsync<CatalogueAdminResponse>("/api/v1/admin/catalogue", Ct);
        var problem = Assert.Single(catalogue!.Problems);
        Assert.Equal("rejected", problem.Status);
        Assert.Equal("Not a real part code.", problem.Reason);
    }

    [Fact]
    public async Task CatalogueContributions_ShouldBackOffAndKeepThePart_WhenThePublisherIsDown()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        var handler = new StubHandler(HttpStatusCode.InternalServerError, "{}");
        var sent = await WithDbAsync(api, (db, clock) =>
            ContributionPush.RunAsync(db, new HttpClient(handler), Options(), clock, null, Ct));

        var contribution = await WithDbAsync(api, (db, _) => db.PartContributions.SingleAsync(Ct));
        Assert.Equal(0, sent);
        Assert.Equal("pending", contribution.Status);
        Assert.Equal(1, contribution.Attempts);
        Assert.True(contribution.NextAttemptAt > contribution.CreatedAt);
    }

    [Fact]
    public async Task CatalogueContributions_ShouldNotBeSent_WhenNoPublisherIsConfigured()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));

        var handler = new StubHandler(HttpStatusCode.OK, """{"accepted":[],"rejected":[]}""");
        var sent = await WithDbAsync(api, (db, clock) =>
            ContributionPush.RunAsync(db, new HttpClient(handler), new CatalogueOptions(), clock, null, Ct));

        Assert.Equal(0, sent);
        Assert.Null(handler.LastParts);
    }

    [Fact]
    public async Task CatalogueAdmin_ShouldBeForbidden_WhenCallerIsNotAnAdmin()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/admin/catalogue", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.GetAsync("/api/v1/admin/catalogue", Ct)).StatusCode);
    }

    [Fact]
    public async Task CatalogueAdmin_ShouldShowTheOutbox_WhenRead()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        await AddChainAsync(member, await AddBikeAsync(member));
        var admin = await AdminAsync(api);

        var catalogue = await admin.GetFromJsonAsync<CatalogueAdminResponse>("/api/v1/admin/catalogue", Ct);

        Assert.Equal(1, catalogue!.Contributions.Pending);
        Assert.False(catalogue.ContributionEndpointConfigured);
        Assert.False(catalogue.ContributionKeyConfigured);
    }

    private sealed class StubHandler(HttpStatusCode status, string body) : HttpMessageHandler
    {
        public string? LastAuthorization { get; private set; }

        public ContributionEntry[]? LastParts { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            LastAuthorization = request.Headers.Authorization?.ToString();
            var json = await request.Content!.ReadAsStringAsync(ct);
            LastParts = JsonSerializer.Deserialize<ContributionSubmission>(
                json, new JsonSerializerOptions(JsonSerializerDefaults.Web))!.Parts;

            return new HttpResponseMessage(status)
            {
                Content = new StringContent(body, Encoding.UTF8, "application/json"),
            };
        }
    }
}
