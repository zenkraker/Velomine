using System.Net;
using System.Net.Http.Json;
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
    public async Task Health_ReturnsOk()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.CreateClient().GetAsync("/health", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
