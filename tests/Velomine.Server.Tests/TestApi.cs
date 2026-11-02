using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>The server running in-process on its own empty database, with a known admin account.</summary>
public sealed class TestApi : IAsyncDisposable
{
    public const string AdminEmail = "admin@test.local";
    public const string AdminPassword = "Admin-password-1";
    public const string MemberPassword = "Member-password-1";

    private readonly WebApplicationFactory<Program> factory;

    private TestApi(WebApplicationFactory<Program> factory) => this.factory = factory;

    public IServiceProvider Services => factory.Services;

    public static async Task<TestApi> StartAsync(PostgresFixture postgres, Action<IWebHostBuilder>? configure = null)
    {
        var connection = await postgres.CreateDatabaseAsync();
        var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseSetting("ConnectionStrings:Velomine", connection);
            builder.UseSetting("Velomine:Admin:Email", AdminEmail);
            builder.UseSetting("Velomine:Admin:Password", AdminPassword);
            configure?.Invoke(builder);
        });
        return new TestApi(factory);
    }

    /// <summary>A client that keeps cookies and does not follow redirects.</summary>
    public HttpClient CreateClient(bool handleCookies = false) =>
        factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false, HandleCookies = handleCookies });

    public static string NewEmail() => $"{Guid.NewGuid():N}@test.local";

    public async Task<HttpResponseMessage> RegisterAsync(string email, string password = MemberPassword, string name = "Test Rider") =>
        await CreateClient().PostAsJsonAsync("/api/v1/accounts/register", new RegisterRequest(email, password, name));

    public async Task<HttpResponseMessage> LoginAsync(string email, string password, bool useCookies = false) =>
        await CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(email, password, useCookies));

    /// <summary>Logs in with a bearer token and returns a client that sends it.</summary>
    public async Task<HttpClient> SignedInClientAsync(string email, string password)
    {
        var response = await LoginAsync(email, password);
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", json.RootElement.GetProperty("accessToken").GetString());
        return client;
    }

    public ValueTask DisposeAsync() => factory.DisposeAsync();
}
