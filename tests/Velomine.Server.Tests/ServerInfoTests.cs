using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests;

[TestClass]
public sealed class ServerInfoTests
{
    private static readonly WebApplicationFactory<Program> Factory = new();

    [TestMethod]
    public async Task ServerInfo_ReturnsNameAndVersion()
    {
        var info = await Factory.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server");

        Assert.AreEqual("Velomine", info?.Name);
        Assert.IsFalse(string.IsNullOrEmpty(info?.Version));
    }

    [TestMethod]
    public async Task Health_ReturnsOk()
    {
        var response = await Factory.CreateClient().GetAsync("/health");

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
    }
}
