using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Velomine.Server.Data;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class ServerInfoTests(PostgresFixture postgres)
{
    [Fact]
    public async Task ServerInfo_ShouldReturnNameAndVersion_WhenRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Equal("Velomine", info?.Name);
        Assert.False(string.IsNullOrEmpty(info?.Version));
        Assert.False(info!.TelemetryEnabled);
        Assert.Null(info.SentryDsn);
    }

    [Fact]
    public async Task ServerInfo_ShouldOfferTelemetry_WhenTheOperatorEnabledIt()
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Telemetry:Enabled", "true");
            b.UseSetting("Velomine:Telemetry:Sentry:Dsn", "https://key@example.invalid/1");
        });

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.True(info!.TelemetryEnabled);
        Assert.Equal("https://key@example.invalid/1", info.SentryDsn);
    }

    [Fact]
    public async Task ServerInfo_ShouldOfferTheDefaultMap_WhenNothingIsConfigured()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Equal(MapOptions.DefaultTileUrl, info!.MapTileUrl);
        Assert.Equal(MapOptions.DefaultAttribution, info.MapAttribution);
    }

    [Fact]
    public async Task ServerInfo_ShouldUseTheConfiguredMap_WhenItIsUsable()
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Map:TileUrl", "https://tiles.example/{z}/{x}/{y}.png");
            b.UseSetting("Velomine:Map:Attribution", "© Example Maps");
        });
        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Equal("https://tiles.example/{z}/{x}/{y}.png", info!.MapTileUrl);
        Assert.Equal("© Example Maps", info.MapAttribution);
    }

    [Theory]
    [InlineData("https://tiles.example/map.png")] // no {z}/{x}/{y}
    [InlineData("tiles.example/{z}/{x}/{y}.png")] // not an address
    [InlineData("javascript:alert({z}{x}{y})")] // not http or https
    public async Task ServerInfo_ShouldFallBackToTheDefaultMap_WhenTheTileAddressIsUnusable(string tileUrl)
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Map:TileUrl", tileUrl);
            b.UseSetting("Velomine:Map:Attribution", "© Example Maps");
        });

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.Equal(MapOptions.DefaultTileUrl, info!.MapTileUrl);
        Assert.Equal(MapOptions.DefaultAttribution, info.MapAttribution);
    }

    [Fact]
    public async Task Health_ShouldReturnOk_WhenProbed()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.CreateClient().GetAsync("/health", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Health_ShouldBeUnhealthy_WhenTheDatabaseCannotBeReached()
    {
        var options = new DbContextOptionsBuilder<VelomineDbContext>()
            .UseNpgsql("Host=127.0.0.1;Port=1;Database=velomine;Username=velomine;Password=velomine;Timeout=1;Command Timeout=1")
            .Options;
        await using var db = new VelomineDbContext(options);

        var result = await new DatabaseHealthCheck(db)
            .CheckHealthAsync(new HealthCheckContext(), TestContext.Current.CancellationToken);

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }
}
