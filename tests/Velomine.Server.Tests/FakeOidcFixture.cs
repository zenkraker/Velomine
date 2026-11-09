using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace Velomine.Server.Tests;

/// <summary>
/// A fake OpenID Connect provider in a pinned official nginx container. It serves discovery, JWKS and userinfo;
/// the tests sign the ID tokens themselves, so wrong issuer, audience, signature and expiry are easy to produce.
/// </summary>
public sealed class FakeOidcFixture : IAsyncLifetime
{
    private const int HostPort = 15557;
    private const string KeyId = "test-key";

    public const string Authority = "http://localhost:15557/dex";
    public const string AppClientId = "velomine-test-app";
    public const string UserInfoEmail = "userinfo@sso.test";

    private const string NginxConfig = """
        server {
            listen 80;
            root /usr/share/nginx/html;
            default_type application/json;
            location / { try_files $uri =404; }
        }
        """;

    private readonly SemaphoreSlim gate = new(1, 1);
    private readonly RSA key = RSA.Create(2048);
    private readonly RSA otherKey = RSA.Create(2048);
    private IContainer? container;
    private string? assetsPath;

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async Task EnsureStartedAsync()
    {
        await gate.WaitAsync();
        try
        {
            if (container is not null) return;

            assetsPath = Path.Combine(Path.GetTempPath(), "velomine-oidc", Guid.NewGuid().ToString("N"));
            var dex = Path.Combine(assetsPath, "dex");
            var wellKnown = Path.Combine(dex, ".well-known");
            Directory.CreateDirectory(wellKnown);
            await File.WriteAllTextAsync(Path.Combine(wellKnown, "openid-configuration"), DiscoveryJson(), Encoding.UTF8);
            await File.WriteAllTextAsync(Path.Combine(dex, "jwks"), JwksJson(), Encoding.UTF8);
            await File.WriteAllTextAsync(
                Path.Combine(dex, "userinfo"),
                $$"""{"sub":"userinfo-sub","email":"{{UserInfoEmail}}","email_verified":true,"name":"User Info Rider"}""",
                Encoding.UTF8);

            container = new ContainerBuilder(
                    "nginx:1.29-alpine@sha256:5616878291a2eed594aee8db4dade5878cf7edcb475e59193904b198d9b830de")
                .WithPortBinding(HostPort, 80)
                .WithResourceMapping(Encoding.UTF8.GetBytes(NginxConfig), "/etc/nginx/conf.d/default.conf")
                .WithResourceMapping(assetsPath, "/usr/share/nginx/html")
                .WithWaitStrategy(
                    Wait.ForUnixContainer()
                        .UntilHttpRequestIsSucceeded(r => r.ForPort(80).ForPath("/dex/.well-known/openid-configuration")))
                .Build();
            await container.StartAsync();
        }
        finally
        {
            gate.Release();
        }
    }

    public string SignToken(
        string subject,
        string? email = null,
        bool? emailVerified = true,
        string? name = "SSO Rider",
        string? issuer = null,
        string? audience = null,
        DateTime? expires = null,
        bool wrongKey = false)
    {
        var claims = new Dictionary<string, object> { ["sub"] = subject };
        if (email is not null) claims["email"] = email;
        if (emailVerified is not null) claims["email_verified"] = emailVerified.Value;
        if (name is not null) claims["name"] = name;

        return new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = issuer ?? Authority,
            Audience = audience ?? AppClientId,
            Claims = claims,
            NotBefore = DateTime.UtcNow.AddMinutes(-1),
            IssuedAt = DateTime.UtcNow.AddMinutes(-1),
            Expires = expires ?? DateTime.UtcNow.AddMinutes(5),
            SigningCredentials = new SigningCredentials(
                new RsaSecurityKey(wrongKey ? otherKey : key) { KeyId = KeyId },
                SecurityAlgorithms.RsaSha256),
        });
    }

    public async ValueTask DisposeAsync()
    {
        if (container is not null) await container.DisposeAsync();
        key.Dispose();
        otherKey.Dispose();
        if (assetsPath is not null && Directory.Exists(assetsPath)) Directory.Delete(assetsPath, recursive: true);
    }

    private static string DiscoveryJson() => JsonSerializer.Serialize(new
    {
        issuer = Authority,
        authorization_endpoint = Authority + "/auth",
        token_endpoint = Authority + "/token",
        jwks_uri = Authority + "/jwks",
        userinfo_endpoint = Authority + "/userinfo",
        response_types_supported = new[] { "code" },
        subject_types_supported = new[] { "public" },
        id_token_signing_alg_values_supported = new[] { "RS256" },
    });

    private string JwksJson()
    {
        var parameters = key.ExportParameters(false);
        return JsonSerializer.Serialize(new
        {
            keys = new[]
            {
                new
                {
                    kty = "RSA",
                    use = "sig",
                    alg = "RS256",
                    kid = KeyId,
                    n = Base64UrlEncoder.Encode(parameters.Modulus),
                    e = Base64UrlEncoder.Encode(parameters.Exponent),
                },
            },
        });
    }
}
