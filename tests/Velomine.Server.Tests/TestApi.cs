using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Npgsql;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests;

/// <summary>A registered member and the client that sends their bearer token.</summary>
public sealed record TestMember(string Email, Guid Id, HttpClient Client);

/// <summary>The server running in-process on its own empty database, with a known admin account.</summary>
public sealed class TestApi : IAsyncDisposable
{
    public const string AdminEmail = "admin@test.local";
    public const string AdminPassword = "Admin-password-1";
    public const string MemberPassword = "Member-password-1";

    private readonly WebApplicationFactory<Program> factory;

    private TestApi(WebApplicationFactory<Program> factory, string connectionString, string filesPath)
    {
        this.factory = factory;
        ConnectionString = connectionString;
        FilesPath = filesPath;
    }

    public string ConnectionString { get; }

    /// <summary>Where this server keeps uploaded ride files. Removed when the test ends.</summary>
    public string FilesPath { get; }

    public IServiceProvider Services => factory.Services;

    public static async Task<TestApi> StartAsync(PostgresFixture postgres, Action<IWebHostBuilder>? configure = null)
    {
        var connection = await postgres.CreateDatabaseAsync();
        var filesPath = Path.Combine(Path.GetTempPath(), "velomine-tests", Guid.NewGuid().ToString("N"));
        var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseSetting("ConnectionStrings:Velomine", connection);
            builder.UseSetting("Velomine:FilesPath", filesPath);
            builder.UseSetting("Velomine:DataProtection:KeysPath", Path.Combine(filesPath, "keys"));
            builder.UseSetting("Velomine:Admin:Email", AdminEmail);
            builder.UseSetting("Velomine:Admin:Password", AdminPassword);
            // Tests start with an empty catalogue unless they ask for the bundled seed.
            builder.UseSetting("Velomine:Catalogue:Seed", "false");
            configure?.Invoke(builder);
        });
        return new TestApi(factory, connection, filesPath);
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

    /// <summary>Registers a new member and returns their signed-in client.</summary>
    public async Task<HttpClient> NewMemberClientAsync()
    {
        var email = NewEmail();
        (await RegisterAsync(email)).EnsureSuccessStatusCode();
        return await SignedInClientAsync(email, MemberPassword);
    }

    /// <summary>Registers a new member and returns their email, id and signed-in client.</summary>
    public async Task<TestMember> NewMemberAsync(string name = "Test Rider")
    {
        var email = NewEmail();
        var response = await RegisterAsync(email, name: name);
        response.EnsureSuccessStatusCode();
        var id = (await response.Content.ReadFromJsonAsync<RegisterResponse>())!.Id;
        return new TestMember(email, id, await SignedInClientAsync(email, MemberPassword));
    }

    /// <summary>Uploads a ride and waits until the background reader has finished with it.</summary>
    public static async Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file, string fileName = "ride.fit")
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(file), "file", fileName } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form);
        accepted.EnsureSuccessStatusCode();
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>())!.RideId;
        for (var i = 0; i < 100; i++)
        {
            var ride = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}");
            if (ride!.Status != "processing") return ride;
            await Task.Delay(100);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

    public async ValueTask DisposeAsync()
    {
        await factory.DisposeAsync();
        // Every test has its own database, so its pooled connections are never reused: close them now, or a long run
        // reaches PostgreSQL's connection limit.
        await using (var connection = new NpgsqlConnection(ConnectionString)) NpgsqlConnection.ClearPool(connection);
        if (Directory.Exists(FilesPath)) Directory.Delete(FilesPath, recursive: true);
    }
}
