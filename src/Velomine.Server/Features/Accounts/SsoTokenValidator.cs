using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace Velomine.Server.Features.Accounts;

/// <summary>Validates the ID token a phone got from the provider, using the provider's discovery document and JWKS.</summary>
public sealed class SsoTokenValidator(
    IOptions<SsoOptions> options,
    IHttpClientFactory clients,
    ILogger<SsoTokenValidator> logger)
{
    private static readonly JsonWebTokenHandler Handler = new();
    private ConfigurationManager<OpenIdConnectConfiguration>? manager;

    private ConfigurationManager<OpenIdConnectConfiguration> Manager
    {
        get
        {
            if (manager is not null) return manager;
            var sso = options.Value;
            manager = new ConfigurationManager<OpenIdConnectConfiguration>(
                sso.Authority!.TrimEnd('/') + "/.well-known/openid-configuration",
                new OpenIdConnectConfigurationRetriever(),
                new HttpDocumentRetriever { RequireHttps = !sso.AllowInsecureHttp });
            return manager;
        }
    }

    public async Task<SsoIdentity?> ValidateAsync(string idToken, string? accessToken, CancellationToken ct)
    {
        var sso = options.Value;
        if (!sso.AppSsoEnabled || string.IsNullOrWhiteSpace(sso.AppClientId)) return null;

        var configuration = await Manager.GetConfigurationAsync(ct);
        TokenValidationResult result;
        try
        {
            result = await Handler.ValidateTokenAsync(idToken, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = configuration.Issuer,
                ValidateAudience = true,
                ValidAudience = sso.AppClientId,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(1),
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = configuration.SigningKeys,
                RequireSignedTokens = true,
            });
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return null; // malformed or unsigned token
        }

        if (!result.IsValid || result.ClaimsIdentity is not { } claims) return null;
        var subject = claims.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(subject)) return null;

        var email = claims.FindFirst("email")?.Value;
        var name = claims.FindFirst("name")?.Value;
        var verified = SsoIdentity.ParseEmailVerified(claims.FindFirst("email_verified")?.Value);

        if (string.IsNullOrWhiteSpace(email) && !string.IsNullOrWhiteSpace(accessToken))
        {
            var info = await ReadUserInfoAsync(configuration.UserInfoEndpoint, accessToken, subject, ct);
            if (info is not null)
            {
                email = info.Email;
                name ??= info.Name;
                verified = info.EmailVerified ?? verified;
            }
        }

        return new SsoIdentity(subject, email, name, verified);
    }

    private async Task<SsoInfo?> ReadUserInfoAsync(string? endpoint, string accessToken, string subject, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(endpoint)) return null;
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            using var response = await clients.CreateClient("sso-userinfo").SendAsync(request, ct);
            if (!response.IsSuccessStatusCode) return null;

            using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            var root = json.RootElement;
            var infoSubject = root.TryGetProperty("sub", out var sub) ? sub.GetString() : null;
            if (infoSubject is not null && infoSubject != subject) return null;

            return new SsoInfo(
                root.TryGetProperty("email", out var email) ? email.GetString() : null,
                root.TryGetProperty("name", out var name) ? name.GetString() : null,
                ReadEmailVerified(root));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Never log the token or the response body.
            logger.LogWarning("The provider's user info could not be read ({Exception}).", ex.GetType().Name);
            return null;
        }
    }

    private static bool? ReadEmailVerified(JsonElement root)
    {
        if (!root.TryGetProperty("email_verified", out var value)) return null;
        return value.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.String => SsoIdentity.ParseEmailVerified(value.GetString()),
            _ => null,
        };
    }

    private sealed record SsoInfo(string? Email, string? Name, bool? EmailVerified);
}
