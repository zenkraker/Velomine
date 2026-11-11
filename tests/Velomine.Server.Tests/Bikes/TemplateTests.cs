using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

[Collection("postgres")]
public sealed class TemplateTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static async Task<Guid> AddBikeAsync(HttpClient client, string name = "Road bike")
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = name, Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static async Task AddChainAsync(HttpClient client, Guid bikeId)
    {
        (await client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", new CreateComponentRequest
        {
            Type = "chain",
            Brand = "Shimano",
            Model = "Ultegra CN-M8100",
            Mpn = "CN-M8100",
            InstalledOn = new DateOnly(2026, 1, 1),
            ExpectedDistanceM = 4000000,
        }, Ct)).EnsureSuccessStatusCode();
    }

    private static CreateTemplateRequest Template(string name = "Gravel build") => new()
    {
        Name = name,
        Parts =
        [
            new TemplatePartRequest
            {
                Type = "chain",
                Brand = "Shimano",
                Model = "CN-M8100",
                Mpn = "CN-M8100",
                ExpectedDistanceM = 4000000,
            },
            new TemplatePartRequest
            {
                Type = "cassette",
                Brand = "Shimano",
                Model = "CS-M8100",
                Mpn = "CS-M8100",
                ExpectedDistanceM = 12000000,
            },
        ],
    };

    private static async Task<T> WithDbAsync<T>(TestApi api, Func<VelomineDbContext, TimeProvider, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(
            scope.ServiceProvider.GetRequiredService<VelomineDbContext>(),
            scope.ServiceProvider.GetRequiredService<TimeProvider>());
    }

    private static async Task AddToSharedCatalogueAsync(TestApi api, string type, string brand, string model, string mpn)
    {
        await WithDbAsync(api, async (db, clock) =>
        {
            db.Parts.Add(new Part
            {
                Id = Guid.CreateVersion7(),
                Key = PartIdentity.Key(type, brand, model, mpn, null)!,
                Type = type,
                Brand = brand,
                Model = model,
                Mpn = mpn,
                Source = CatalogueSync.SharedSource,
                CreatedAt = clock.GetUtcNow(),
            });
            await db.SaveChangesAsync(Ct);
            return true;
        });
    }

    private static async Task<BikeTemplateResponse> CreateTemplateAsync(HttpClient client, CreateTemplateRequest request)
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes/templates", request, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeTemplateResponse>(Ct))!;
    }

    [Fact]
    public async Task Template_ShouldCopyTheFittedParts_WhenSavedFromABike()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);
        await AddChainAsync(member, bikeId);

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates",
            new SaveBikeAsTemplateRequest { Name = "Gravel build" }, Ct);
        response.EnsureSuccessStatusCode();

        var template = await response.Content.ReadFromJsonAsync<BikeTemplateResponse>(Ct);
        Assert.Equal("Gravel build", template!.Name);
        var part = Assert.Single(template.Parts);
        Assert.Equal("chain", part.Type);
        Assert.Equal("Shimano", part.Brand);
        Assert.Equal("CN-M8100", part.Mpn);
        Assert.False(part.IsCustom);
        Assert.Equal(4000000, part.ExpectedDistanceM);

        var list = await member.GetFromJsonAsync<ListTemplatesResponse>("/api/v1/bikes/templates", Ct);
        Assert.Single(list!.Templates);
    }

    [Fact]
    public async Task Template_ShouldFillOnlyTheMissingParts_WhenApplied()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);
        await AddToSharedCatalogueAsync(api, "chain", "Shimano", "CN-M8100", "CN-M8100");
        await AddToSharedCatalogueAsync(api, "cassette", "Shimano", "CS-M8100", "CS-M8100");
        await AddChainAsync(member, bikeId);
        var template = await CreateTemplateAsync(member, Template());

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates/{template.Id}",
            new ApplyTemplateRequest { InstalledOn = new DateOnly(2026, 2, 1) }, Ct);
        response.EnsureSuccessStatusCode();

        var detail = await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        Assert.Equal(2, detail!.Components.Length);
        var chain = detail.Components.Single(c => c.Type == "chain");
        Assert.Equal(new DateOnly(2026, 1, 1), chain.InstalledOn); // the part already fitted was left alone
        var cassette = detail.Components.Single(c => c.Type == "cassette");
        Assert.Equal(new DateOnly(2026, 2, 1), cassette.InstalledOn);
        Assert.Equal(12000000, cassette.ExpectedDistanceM);
        Assert.NotNull(cassette.PartId);

        var search = await member.GetFromJsonAsync<SearchPartsResponse>("/api/v1/bikes/parts?q=CS-M8100", Ct);
        Assert.Equal("Shimano", Assert.Single(search!.Parts).Brand);
    }

    [Fact]
    public async Task Template_ShouldBeRejected_WhenTheBikeHasNoParts()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates",
            new SaveBikeAsTemplateRequest { Name = "Empty" }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Template_ShouldBeRemoved_WhenDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var template = await CreateTemplateAsync(member, Template());

        var deleted = await member.DeleteAsync($"/api/v1/bikes/templates/{template.Id}", Ct);
        var list = await member.GetFromJsonAsync<ListTemplatesResponse>("/api/v1/bikes/templates", Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        Assert.Empty(list!.Templates);
    }

    [Fact]
    public async Task Template_ShouldKeepACustomPartCustom_WhenApplied()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);
        var template = await CreateTemplateAsync(member, new CreateTemplateRequest
        {
            Name = "Custom saddle",
            Parts =
            [
                new TemplatePartRequest
                {
                    Type = "saddle",
                    Brand = "My own",
                    Model = "Recovered saddle",
                    IsCustom = true,
                },
            ],
        });

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/templates/{template.Id}",
            new ApplyTemplateRequest { InstalledOn = new DateOnly(2026, 2, 1) }, Ct);
        response.EnsureSuccessStatusCode();
        var detail = await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);

        var saddle = Assert.Single(detail!.Components);
        Assert.True(saddle.IsCustom);
        Assert.Null(saddle.PartId);
        Assert.Equal(0, await WithDbAsync(api, (db, _) => db.PartContributions.CountAsync(Ct)));
    }

    [Fact]
    public async Task Template_ShouldNotBeVisibleToAnotherMember_WhenTheyAsk()
    {
        await using var api = await StartAsync();
        var owner = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        var ownerBike = await AddBikeAsync(owner, "Owner bike");
        await AddChainAsync(owner, ownerBike);
        var template = await CreateTemplateAsync(owner, Template());
        var otherBike = await AddBikeAsync(other, "Other bike");

        var list = await other.GetFromJsonAsync<ListTemplatesResponse>("/api/v1/bikes/templates", Ct);
        var apply = await other.PostAsJsonAsync($"/api/v1/bikes/{otherBike}/templates/{template.Id}",
            new ApplyTemplateRequest { InstalledOn = new DateOnly(2026, 2, 1) }, Ct);
        var save = await other.PostAsJsonAsync($"/api/v1/bikes/{ownerBike}/templates",
            new SaveBikeAsTemplateRequest { Name = "Stolen" }, Ct);

        Assert.Empty(list!.Templates);
        Assert.Equal(HttpStatusCode.NotFound, apply.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, save.StatusCode);
    }

    [Fact]
    public async Task Template_ShouldNotBeVisible_WhenRequestComesFromAnotherTenant()
    {
        await using var one = await StartAsync();
        await using var two = await StartAsync();
        var mine = await NewMemberAsync(one);
        var theirs = await NewMemberAsync(two);
        await CreateTemplateAsync(mine, Template());

        var list = await theirs.GetFromJsonAsync<ListTemplatesResponse>("/api/v1/bikes/templates", Ct);

        Assert.Empty(list!.Templates);
    }
}
