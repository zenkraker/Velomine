using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

[Collection("postgres")]
public sealed class PartCatalogueTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<HttpClient> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return await api.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    private static async Task<Guid> AddBikeAsync(HttpClient client, string name = "Road bike")
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes",
            new CreateBikeRequest { Name = name, Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!.Bike.Id;
    }

    private static CreateComponentRequest Chain(string? brand = "Shimano", string? model = "Ultegra CN-M8100", string? mpn = "CN-M8100", string? gtin = null) =>
        new() { Type = "chain", Brand = brand, Model = model, Mpn = mpn, Gtin = gtin, InstalledOn = new DateOnly(2026, 1, 1) };

    private static async Task<ComponentResponse> AddChainAsync(HttpClient client, Guid bikeId, CreateComponentRequest chain)
    {
        var response = await client.PostAsJsonAsync($"/api/v1/bikes/{bikeId}/components", chain, Ct);
        response.EnsureSuccessStatusCode();
        var detail = await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        return Assert.Single(detail!.Components);
    }

    private static async Task<PartResponse[]> SearchAsync(HttpClient client, string query) =>
        (await client.GetFromJsonAsync<SearchPartsResponse>($"/api/v1/bikes/parts?q={Uri.EscapeDataString(query)}", Ct))!.Parts;

    [Fact]
    public async Task PartCatalogue_ShouldRememberThePart_WhenAComponentIsAddedWithItsPartNumber()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bikeId = await AddBikeAsync(member);

        var chain = await AddChainAsync(member, bikeId, Chain());

        Assert.NotNull(chain.PartId);
        var part = Assert.Single(await SearchAsync(member, "CN-M8100"));
        Assert.Equal("Shimano", part.Brand);
        Assert.Equal("Ultegra CN-M8100", part.Model);
        Assert.Equal("CN-M8100", part.Mpn);
        Assert.Equal(1, part.Confirmations);
    }

    [Fact]
    public async Task PartCatalogue_ShouldReuseTheEntry_WhenTheSamePartIsTypedInAnotherCase()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var first = await AddBikeAsync(member, "One");
        var second = await AddBikeAsync(member, "Two");

        var one = await AddChainAsync(member, first, Chain("Shimano", "Ultegra", "CN-M8100"));
        var two = await AddChainAsync(member, second, Chain("shimano", "Ultegra chain", "cn-m8100"));

        Assert.Equal(one.PartId, two.PartId);
        var part = Assert.Single(await SearchAsync(member, "ultegra"));
        Assert.Equal(2, part.Confirmations);
    }

    [Fact]
    public async Task PartCatalogue_ShouldReuseTheEntry_WhenTheSameGtinArrivesUnderAnotherName()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var first = await AddBikeAsync(member, "One");
        var second = await AddBikeAsync(member, "Two");

        var one = await AddChainAsync(member, first, Chain(gtin: "4006381333931"));
        var two = await AddChainAsync(member, second, Chain("Shimano", "HG701 11-speed", null, "4006381333931"));

        Assert.Equal(one.PartId, two.PartId);
        var part = Assert.Single(await SearchAsync(member, "Ultegra"));
        Assert.Equal("04006381333931", part.Gtin);
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
    public async Task PartCatalogue_ShouldNotBeVisible_WhenRequestComesFromAnotherTenant()
    {
        await using var one = await StartAsync();
        await using var two = await StartAsync();
        var mine = await NewMemberAsync(one);
        var theirs = await NewMemberAsync(two);
        var bikeId = await AddBikeAsync(mine);

        await AddChainAsync(mine, bikeId, Chain());

        Assert.Single(await SearchAsync(mine, "Shimano"));
        Assert.Empty(await SearchAsync(theirs, "Shimano"));
    }
}
