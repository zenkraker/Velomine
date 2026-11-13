using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Velomine.Server.Tests;

/// <summary>
/// Every operation the OpenAPI document marks as needing a sign-in answers 401 without one. One test over the whole
/// document instead of one test per endpoint: a new endpoint that forgets its authorization is caught here.
/// </summary>
public sealed class SignInRequiredTests(PostgresFixture postgres)
{
    // The sign-in and recovery endpoints, the share views and the download links carry their own token or nothing.
    private static readonly string[] OpenWithoutASession =
    [
        "register", "login", "loginTwoFactor", "refresh", "forgotPassword", "resetPassword", "downloadExport",
        "readSharedRide", "readCalendarFeed", "downloadRoute",
    ];

    [Fact]
    public async Task Endpoints_ShouldRequireASignIn_WhenCalledWithoutAToken()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:RateLimits:AnonymousPerMinute", "100000"));
        var client = api.CreateClient();
        var document = await client.GetFromJsonAsync<JsonElement>("/openapi/v1.json", TestContext.Current.CancellationToken);

        var secured = document.GetProperty("paths").EnumerateObject()
            .SelectMany(path => path.Value.EnumerateObject()
                .Where(operation => operation.Value.TryGetProperty("security", out _))
                .Select(operation => (
                    Id: operation.Value.GetProperty("operationId").GetString()!,
                    Method: ToMethod(operation.Name),
                    // The document writes {id} where a request puts a value.
                    Path: path.Name.Replace("{", "").Replace("}", ""))))
            .Where(endpoint => !OpenWithoutASession.Contains(endpoint.Id))
            .ToList();

        Assert.True(secured.Count > 100, $"Only {secured.Count} secured operations were found; the document did not load.");

        var allowed = new List<string>();
        foreach (var endpoint in secured)
        {
            using var request = new HttpRequestMessage(endpoint.Method, endpoint.Path);
            if (endpoint.Method != HttpMethod.Get && endpoint.Method != HttpMethod.Delete)
                request.Content = JsonContent.Create(new { });
            var response = await client.SendAsync(request, TestContext.Current.CancellationToken);
            // A multipart upload is turned away by the form reader before the handler; the endpoint still asks for a sign-in.
            if (response.StatusCode != HttpStatusCode.Unauthorized) allowed.Add($"{endpoint.Method} {endpoint.Path} {(int)response.StatusCode}");
        }

        Assert.Empty(allowed);
    }

    private static HttpMethod ToMethod(string verb) => verb switch
    {
        "get" => HttpMethod.Get,
        "post" => HttpMethod.Post,
        "put" => HttpMethod.Put,
        "patch" => HttpMethod.Patch,
        "delete" => HttpMethod.Delete,
        _ => throw new InvalidOperationException($"Unknown method {verb} in the OpenAPI document."),
    };
}
