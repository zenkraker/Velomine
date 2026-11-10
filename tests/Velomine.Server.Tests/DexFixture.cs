using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using Microsoft.IdentityModel.Tokens;

namespace Velomine.Server.Tests;

/// <summary>
/// The real OpenID Connect provider (Dex) for the single sign-on tests, started from the same
/// <c>deploy/dex/config.yaml</c> as <c>docker compose</c>: the same users, clients and secrets. Only the issuer
/// changes, to a port that does not clash with a running development stack. Starts on first use.
/// </summary>
public sealed partial class DexFixture : IAsyncLifetime
{
    private const int HostPort = 15556; // fixed: the issuer in the ID token must match what the server is configured with

    public const string Authority = "http://localhost:15556/dex";
    public const string ClientId = "velomine";
    public const string ClientSecret = "velomine-dev-secret";
    public const string AppClientId = "velomine-app";
    public const string AppRedirectUri = "com.velomine.app:/sso-callback";
    public const string WebRedirectUri = "http://localhost/signin-oidc"; // the test server's address
    public const string VerifiedEmail = "rider@sso.test";
    public const string UnverifiedEmail = "unverified@sso.test";
    public const string Password = "password";

    private readonly SemaphoreSlim gate = new(1, 1);
    private IContainer? container;

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async Task EnsureStartedAsync()
    {
        await gate.WaitAsync();
        try
        {
            if (container is not null) return;
            var config = IssuerLine().Replace(await File.ReadAllTextAsync(DevConfigPath()), $"issuer: {Authority}");
            container = new ContainerBuilder("ghcr.io/dexidp/dex:v2.46.1")
                .WithPortBinding(HostPort, 5556)
                .WithResourceMapping(Encoding.UTF8.GetBytes(config), "/etc/dex/config.yaml")
                .WithCommand("dex", "serve", "/etc/dex/config.yaml")
                .WithWaitStrategy(Wait.ForUnixContainer().UntilHttpRequestIsSucceeded(r => r.ForPort(5556).ForPath("/dex/.well-known/openid-configuration")))
                .Build();
            await container.StartAsync();
        }
        finally
        {
            gate.Release();
        }
    }

    /// <summary>
    /// Plays the browser on Dex's login page from <paramref name="start"/> until Dex redirects to
    /// <paramref name="redirectUri"/>, and returns that redirect.
    /// </summary>
    public static async Task<Uri> SignInOnProviderAsync(Uri start, string email, string redirectUri, CancellationToken ct)
    {
        using var browser = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false, UseCookies = true });
        var current = start;
        for (var hop = 0; hop < 12; hop++)
        {
            var response = await browser.GetAsync(current, ct);
            if (response.StatusCode == HttpStatusCode.OK)
            {
                // Dex's login form: post the email and password to the form's own address.
                var html = await response.Content.ReadAsStringAsync(ct);
                var action = WebUtility.HtmlDecode(FormAction().Match(html).Groups[1].Value);
                response = await browser.PostAsync(
                    new Uri(current, action),
                    new FormUrlEncodedContent(new Dictionary<string, string> { ["login"] = email, ["password"] = Password }),
                    ct);
            }

            Assert.True((int)response.StatusCode is >= 300 and < 400, $"Unexpected {(int)response.StatusCode} from the provider at {current}");
            var next = new Uri(current, response.Headers.Location!);
            if (next.AbsoluteUri.StartsWith(redirectUri, StringComparison.Ordinal)) return next;
            current = next;
        }

        throw new InvalidOperationException($"Dex never redirected to {redirectUri}.");
    }

    /// <summary>
    /// Signs <paramref name="email"/> in with the authorization code flow and PKCE, as the phone does, and returns
    /// the provider's ID token and access token. The web client needs its secret; the phone client is public.
    /// </summary>
    public async Task<(string IdToken, string AccessToken)> TokensAsync(
        string email, CancellationToken ct, string clientId = AppClientId, string redirectUri = AppRedirectUri, string? clientSecret = null)
    {
        await EnsureStartedAsync();
        var verifier = Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(32));
        var challenge = Base64UrlEncoder.Encode(SHA256.HashData(Encoding.ASCII.GetBytes(verifier)));
        var authorize = new Uri(
            $"{Authority}/auth?response_type=code&scope=openid%20email%20profile&state=test" +
            $"&client_id={Uri.EscapeDataString(clientId)}&redirect_uri={Uri.EscapeDataString(redirectUri)}" +
            $"&code_challenge={challenge}&code_challenge_method=S256");

        var callback = await SignInOnProviderAsync(authorize, email, redirectUri, ct);
        var code = CodeParameter().Match(callback.Query).Groups[1].Value;

        var form = new Dictionary<string, string>
        {
            ["grant_type"] = "authorization_code",
            ["code"] = Uri.UnescapeDataString(code),
            ["redirect_uri"] = redirectUri,
            ["client_id"] = clientId,
            ["code_verifier"] = verifier,
        };
        if (clientSecret is not null) form["client_secret"] = clientSecret;

        using var http = new HttpClient();
        var response = await http.PostAsync($"{Authority}/token", new FormUrlEncodedContent(form), ct);
        Assert.True(response.IsSuccessStatusCode, await response.Content.ReadAsStringAsync(ct));
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return (json.RootElement.GetProperty("id_token").GetString()!, json.RootElement.GetProperty("access_token").GetString()!);
    }

    public async ValueTask DisposeAsync()
    {
        if (container is not null) await container.DisposeAsync();
    }

    private static string DevConfigPath()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            var path = Path.Combine(dir.FullName, "deploy", "dex", "config.yaml");
            if (File.Exists(path)) return path;
        }

        throw new FileNotFoundException("deploy/dex/config.yaml not found above the test output folder.");
    }

    [GeneratedRegex("^issuer: .*$", RegexOptions.Multiline)]
    private static partial Regex IssuerLine();

    [GeneratedRegex("action=\"([^\"]+)\"")]
    private static partial Regex FormAction();

    [GeneratedRegex("[?&]code=([^&]+)")]
    private static partial Regex CodeParameter();
}
