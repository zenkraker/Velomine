using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Velomine.Server.Data;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests;

public sealed class ServerInfoTests(PostgresFixture postgres) : IAsyncLifetime
{
    // Both rows only ask the default server for a path it does not serve; one server answers them.
    private TestApi? shared;

    public async ValueTask InitializeAsync() => shared = await TestApi.StartAsync(postgres);

    public async ValueTask DisposeAsync()
    {
        if (shared is not null) await shared.DisposeAsync();
    }

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
            b.UseSetting("Velomine:Telemetry:Errors:Dsn", "https://key@example.invalid/1");
        });

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.True(info!.TelemetryEnabled);
        Assert.Equal("https://key@example.invalid/1", info.SentryDsn);
    }

    [Fact]
    public async Task ServerInfo_ShouldUseTheAppProjectDsn_WhenItIsConfigured()
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Telemetry:Enabled", "true");
            b.UseSetting("Velomine:Telemetry:Errors:Dsn", "https://server@example.invalid/1");
            b.UseSetting("Velomine:Telemetry:App:Dsn", "https://app@example.invalid/2");
        });

        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", TestContext.Current.CancellationToken);

        Assert.True(info!.TelemetryEnabled);
        Assert.Equal("https://app@example.invalid/2", info.SentryDsn);
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

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    public async Task Server_ShouldNotServeFrontEndPaths_WhenTheWebImageOwnsThem(string path)
    {
        var response = await shared!.CreateClient().GetAsync(path, TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
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
