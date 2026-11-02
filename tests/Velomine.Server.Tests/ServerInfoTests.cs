using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class ServerInfoTests(PostgresFixture postgres)
{
    [Fact]
    public async Task ServerInfo_ReturnsNameAndVersion()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Equal("Velomine", info?.Name);
        Assert.False(string.IsNullOrEmpty(info?.Version));
    }

    [Fact]
    public async Task ServerInfo_OffersNoMapTiles_UnlessAnAdminSetsAUsableAddress()
    {
        await using var off = await TestApi.StartAsync(postgres);
        var none = await off.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);
        Assert.Null(none!.MapTileUrl);

        await using var on = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Map:TileUrl", "https://tiles.example/{z}/{x}/{y}.png");
            b.UseSetting("Velomine:Map:Attribution", "© Example Maps");
        });
        var set = await on.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);
        Assert.Equal("https://tiles.example/{z}/{x}/{y}.png", set!.MapTileUrl);
        Assert.Equal("© Example Maps", set.MapAttribution);
    }

    [Theory]
    [InlineData("https://tiles.example/map.png")] // no {z}/{x}/{y}
    [InlineData("tiles.example/{z}/{x}/{y}.png")] // not an address
    [InlineData("javascript:alert({z}{x}{y})")] // not http or https
    public async Task ServerInfo_IgnoresAnUnusableTileAddress(string tileUrl)
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Map:TileUrl", tileUrl);
            b.UseSetting("Velomine:Map:Attribution", "© Example Maps");
        });

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Null(info!.MapTileUrl);
        Assert.Null(info.MapAttribution);
    }

    [Fact]
    public async Task Health_ReturnsOk()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.CreateClient().GetAsync("/health", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
