using System.Text;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;

namespace Velomine.Server.Tests;

/// <summary>
/// A real OpenID Connect provider (Dex) for the SSO tests. Starts on first use, so test runs that do not need it
/// do not pay for it. Dev and test only. Users: rider@sso.test (email verified) and unverified@sso.test, password "password".
/// </summary>
public sealed class DexFixture : IAsyncLifetime
{
    private const int HostPort = 15556; // fixed: the issuer URL in the ID token must match what the server is configured with

    public const string Authority = "http://localhost:15556/dex";
    public const string ClientId = "velomine-test";
    public const string ClientSecret = "velomine-test-secret";
    public const string VerifiedEmail = "rider@sso.test";
    public const string UnverifiedEmail = "unverified@sso.test";
    public const string Password = "password";

    // The test server's address is http://localhost/, so that is the redirect URI the provider must accept.
    private const string Config = $"""
        issuer: {Authority}
        storage:
          type: memory
        web:
          http: 0.0.0.0:5556
        oauth2:
          skipApprovalScreen: true
        enablePasswordDB: true
        staticClients:
          - id: {ClientId}
            name: Velomine tests
            secret: {ClientSecret}
            redirectURIs:
              - http://localhost/signin-oidc
        staticPasswords:
          - email: {VerifiedEmail}
            hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
            username: rider
            name: SSO Rider
            emailVerified: true
            userID: 08a8684b-db88-4b73-90a9-3cd1661f5466
          - email: {UnverifiedEmail}
            hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
            username: unverified
            name: Unverified Rider
            emailVerified: false
            userID: 17b4a4c4-6b0d-4c5e-9d52-0a6a1f4b2a11
        """;

    private readonly SemaphoreSlim gate = new(1, 1);
    private IContainer? container;

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async Task EnsureStartedAsync()
    {
        await gate.WaitAsync();
        try
        {
            if (container is not null) return;
            container = new ContainerBuilder("ghcr.io/dexidp/dex:v2.46.1")
                .WithPortBinding(HostPort, 5556)
                .WithResourceMapping(Encoding.UTF8.GetBytes(Config), "/etc/dex/config.yaml")
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

    public async ValueTask DisposeAsync()
    {
        if (container is not null) await container.DisposeAsync();
    }
}
