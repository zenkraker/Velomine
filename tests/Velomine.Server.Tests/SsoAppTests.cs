using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>
/// The phone's direct OpenID Connect flow: an ID token from the real provider (Dex, same configuration as development)
/// exchanged for Velomine bearer tokens.
/// </summary>
public sealed class SsoAppTests(PostgresFixture postgres, DexFixture dex)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private async Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null)
    {
        await dex.EnsureStartedAsync();
        return await TestApi.StartAsync(postgres, builder =>
        {
            builder.UseSetting("Velomine:Sso:Authority", dex.Authority);
            builder.UseSetting("Velomine:Sso:AppClientId", DexFixture.AppClientId);
            builder.UseSetting("Velomine:Sso:AllowInsecureHttp", "true");
            builder.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            more?.Invoke(builder);
        });
    }

    private static Task<HttpResponseMessage> ExchangeAsync(HttpClient client, string idToken, string? accessToken = null) =>
        client.PostAsJsonAsync("/api/v1/accounts/sso/token", new ExchangeSsoTokenRequest(idToken, accessToken), Ct);

    private static async Task<string?> ErrorAsync(HttpResponseMessage response)
    {
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        return json.RootElement.TryGetProperty("error", out var error) ? error.GetString() : null;
    }

    private static async Task<HttpClient> SignedInAsync(TestApi api, string idToken)
    {
        var response = await ExchangeAsync(api.CreateClient(), idToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", json.RootElement.GetProperty("accessToken").GetString());
        return client;
    }

    private static async Task AssertNoUserAsync(TestApi api, string email)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.Users.AnyAsync(u => u.Email == email, Ct));
    }

    /// <summary>Flips one character in the middle of the token's signature, so only the signature is wrong.</summary>
    private static string TamperWithSignature(string token)
    {
        var dot = token.LastIndexOf('.');
        var middle = dot + (token.Length - dot) / 2;
        var swapped = token[middle] == 'A' ? 'B' : 'A';
        return string.Concat(token.AsSpan(0, middle), swapped.ToString(), token.AsSpan(middle + 1));
    }

    [Fact]
    public async Task SsoApp_ShouldReportAppSettings_WhenTheInfoEndpointIsCalled()
    {
        await using var api = await StartAsync();
        var info = await api.CreateClient().GetFromJsonAsync<SsoInfoResponse>("/api/v1/accounts/sso", Ct);

        Assert.False(info!.Enabled);
        Assert.Null(info.LoginUrl);
        Assert.True(info.AppSsoEnabled);
        Assert.Equal(dex.Authority, info.AppAuthority);
        Assert.Equal(DexFixture.AppClientId, info.AppClientId);
        Assert.Contains("openid", info.AppScopes);
        Assert.Equal("com.velomine.app:/sso-callback", info.AppRedirectUri);
    }

    [Fact]
    public async Task SsoApp_ShouldReturnTokensAndTheMember_WhenTheTokenIsValid()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.VerifiedEmail;
        var (idToken, _) = await dex.TokensAsync(email, Ct);

        var response = await ExchangeAsync(api.CreateClient(), idToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        Assert.False(string.IsNullOrEmpty(json.RootElement.GetProperty("accessToken").GetString()));
        Assert.False(string.IsNullOrEmpty(json.RootElement.GetProperty("refreshToken").GetString()));

        var client = await SignedInAsync(api, idToken);
        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal(email, me!.Email);
        Assert.Equal("SSO Rider", me.DisplayName);
        Assert.Equal(["member"], me.Roles);
    }

    [Fact]
    public async Task SsoApp_ShouldRejectTheToken_WhenTheAudienceIsWrong()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.VerifiedEmail;
        // A genuine token, but issued to the web client, not the phone app.
        var (idToken, _) = await dex.TokensAsync(
            email, Ct, DexFixture.ClientId, DexFixture.WebRedirectUri, DexFixture.ClientSecret);

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        await AssertNoUserAsync(api, email);
    }

    [Fact]
    public async Task SsoApp_ShouldRejectTheToken_WhenTheSignatureIsBad()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.VerifiedEmail;
        var (genuine, _) = await dex.TokensAsync(email, Ct);
        var idToken = TamperWithSignature(genuine);

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        await AssertNoUserAsync(api, email);
    }

    [Fact]
    public async Task SsoApp_ShouldRejectAnUnverifiedEmail_WhenCreatingAnAccount()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.UnverifiedEmail;
        var (idToken, _) = await dex.TokensAsync(email, Ct);

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("email_not_verified", await ErrorAsync(response));
        await AssertNoUserAsync(api, email);
    }

    [Fact]
    public async Task SsoApp_ShouldWaitForApproval_WhenTheAccountIsNew()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "true"));
        const string email = DexFixture.VerifiedEmail;
        var (idToken, _) = await dex.TokensAsync(email, Ct);

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("not_approved", await ErrorAsync(response));

        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var waiting = await admin.GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users?pending=true", Ct);
        Assert.Contains(waiting!, u => u.Email == email);
    }

    [Fact]
    public async Task SsoApp_ShouldReuseTheExistingAccount_WhenTheEmailMatches()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.VerifiedEmail;
        var registered = await (await api.RegisterAsync(email)).Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        var (idToken, _) = await dex.TokensAsync(email, Ct);

        var client = await SignedInAsync(api, idToken);

        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal(registered!.Id, me!.Id);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(1, await db.Users.CountAsync(u => u.Email == email, Ct));
    }

    [Fact]
    public async Task SsoApp_ShouldRejectTheAccount_WhenItIsLockedOut()
    {
        await using var api = await StartAsync();
        const string email = DexFixture.VerifiedEmail;
        var (idToken, _) = await dex.TokensAsync(email, Ct);
        Assert.Equal(HttpStatusCode.OK, (await ExchangeAsync(api.CreateClient(), idToken)).StatusCode);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = await db.Users.SingleAsync(u => u.Email == email, Ct);
            await users.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow.AddDays(1));
        }

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal((HttpStatusCode)423, response.StatusCode);
        Assert.Equal("locked_out", await ErrorAsync(response));
    }

    [Fact]
    public async Task SsoApp_ShouldRefuseUnknownAccounts_WhenAutoCreateIsOff()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Sso:AutoCreateUsers", "false"));
        const string email = DexFixture.VerifiedEmail;
        var (idToken, _) = await dex.TokensAsync(email, Ct);

        var response = await ExchangeAsync(api.CreateClient(), idToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("no_account", await ErrorAsync(response));
        await AssertNoUserAsync(api, email);
    }
}
