using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

public sealed class PartCatalogueTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static async Task<Guid> AddBikeAsync(HttpClient client, string name = "Road bike")
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = name, Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static CreateComponentRequest Chain(string? brand = "Shimano", string? model = "Ultegra CN-M8100", string? mpn = "CN-M8100", string? gtin = null, bool custom = false) =>
        new() { Type = "chain", Brand = brand, Model = model, Mpn = mpn, Gtin = gtin, Custom = custom, InstalledOn = new DateOnly(2026, 1, 1) };

    private static async Task<ComponentResponse> AddChainAsync(HttpClient client, Guid bikeId, CreateComponentRequest chain)
    {
        var response = await client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", chain, Ct);
        response.EnsureSuccessStatusCode();
        var detail = await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        return Assert.Single(detail!.Components);
    }

    private static async Task<PartResponse[]> SearchAsync(HttpClient client, string query) =>
        (await client.GetFromJsonAsync<SearchPartsResponse>($"/api/v1/bikes/parts?q={Uri.EscapeDataString(query)}", Ct))!.Parts;

    private static async Task AddToSharedCatalogueAsync(TestApi api, string model = "Ultegra CN-M8100", string? mpn = "CN-M8100", string? gtin = null)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var time = scope.ServiceProvider.GetRequiredService<TimeProvider>();
        var part = new Part
        {
            Id = Guid.CreateVersion7(),
            Key = PartIdentity.Key("chain", "Shimano", model, mpn, gtin)!,
            Type = "chain",
            Brand = "Shimano",
            Model = model,
            Mpn = mpn,
            Gtin = gtin,
            Source = CatalogueSync.SharedSource,
            CreatedAt = time.GetUtcNow(),
        };
        db.Parts.Add(part);
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task Component_ShouldLinkToTheSharedPart_WhenTheCatalogueHasIt()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);
        await AddToSharedCatalogueAsync(api);

        var chain = await AddChainAsync(member, bikeId, Chain());

        Assert.NotNull(chain.PartId);
        Assert.False(chain.IsCustom);
        var part = Assert.Single(await SearchAsync(member, "CN-M8100"));
        Assert.Equal("Shimano", part.Brand);
    }

    [Fact]
    public async Task Component_ShouldMatchTheSharedPartByGtin_WhenTheBrandAndNameDiffer()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);
        // The publisher lists the pad under a code, with a barcode; the member types a different name.
        await AddToSharedCatalogueAsync(api, "HG701 11-speed", null, "4006381333931");

        var chain = await AddChainAsync(member, bikeId, Chain("Shimano", "Different name", null, "4006381333931"));

        // The barcode identifies the part on its own, so the member's part is linked to the publisher's row and its
        // GTIN is stored in the normalised fourteen-digit form.
        Assert.NotNull(chain.PartId);
        Assert.Equal("04006381333931", chain.Gtin);
        // The linked part is the publisher's row, not a copy the member's entry created.
        Assert.Single(await SearchAsync(member, "HG701"));
    }

    [Fact]
    public async Task Component_ShouldStayUnlinked_WhenThePublisherHasNotListedThePart()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var chain = await AddChainAsync(member, bikeId, Chain());

        Assert.Null(chain.PartId);
        Assert.Empty(await SearchAsync(member, "CN-M8100"));
    }

    [Fact]
    public async Task Component_ShouldNotBeLinkedOrContributed_WhenItIsCustom()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var chain = await AddChainAsync(member, bikeId, Chain(custom: true));

        Assert.Null(chain.PartId);
        Assert.True(chain.IsCustom);
        Assert.Empty(await SearchAsync(member, "CN-M8100"));
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(0, await db.PartContributions.CountAsync(Ct));
    }

    [Fact]
    public async Task Component_ShouldStoreTheGtinAsFourteenDigits_WhenTheBarcodeIsValid()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var chain = await AddChainAsync(member, bikeId, Chain(gtin: "4006381333931"));

        Assert.Equal("04006381333931", chain.Gtin);
    }

    [Fact]
    public async Task Component_ShouldBeRejected_WhenTheBarcodeIsNotAValidGtin()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var response = await member.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", Chain(gtin: "4006381333932"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task PartCatalogue_ShouldBeSharedByEveryMember_WhenThePublisherListsThePart()
    {
        await using var api = await StartAsync();
        var mine = await NewMemberAsync(api);
        var theirs = await NewMemberAsync(api);
        await AddToSharedCatalogueAsync(api);

        Assert.Single(await SearchAsync(mine, "Shimano"));
        Assert.Single(await SearchAsync(theirs, "Shimano"));
    }
}
