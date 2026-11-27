using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>
/// What a security change ends: it moves the account's security stamp, and Identity refuses every older cookie and
/// refresh token. A member who loses a phone or a password must be able to get everyone else out.
/// </summary>
public sealed class SessionRevocationTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(string Access, string Refresh)> LoginAsync(
        TestApi api, string email = TestApi.AdminEmail, string password = TestApi.AdminPassword)
    {
        var response = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(email, password), Ct);
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        return (json.RootElement.GetProperty("accessToken").GetString()!, json.RootElement.GetProperty("refreshToken").GetString()!);
    }

    private static HttpClient WithToken(TestApi api, string token)
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task PasswordChange_ShouldEndEveryRefreshToken_WhenThePasswordIsChanged()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var first = await LoginAsync(api, email, TestApi.MemberPassword);
        var second = await LoginAsync(api, email, TestApi.MemberPassword);

        var change = await WithToken(api, first.Access).PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest(TestApi.MemberPassword, "Another-password-1"), Ct);

        Assert.Equal(HttpStatusCode.NoContent, change.StatusCode);
        // Both phones are out: even the one that made the change cannot refresh.
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(first.Refresh), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(second.Refresh), Ct)).StatusCode);
    }

    [Fact]
    public async Task AdminTwoFactorReset_ShouldEndEveryRefreshTokenOfThatAccount_WhenItIsReset()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        // A member with two devices and their second factor on; an admin resets the factor.
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var first = await LoginAsync(api, email, TestApi.MemberPassword);
        var second = await LoginAsync(api, email, TestApi.MemberPassword);
        await EnableAsync(api, email, TestApi.MemberPassword);
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.Identity.UserManager<User>>();
        var member = await users.FindByEmailAsync(email);

        var reset = await (await AdminAsync(api)).PostAsync($"/api/v1/admin/users/{member!.Id}/two-factor/reset", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        // The reset moves the security stamp: neither refresh token works any more.
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(first.Refresh), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(second.Refresh), Ct)).StatusCode);
    }

    [Fact]
    public async Task DisableTwoFactor_ShouldBeRefused_WhenThePasswordIsWrong()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (client, _, _) = await EnableAsync(api);

        var wrong = await client.PostAsJsonAsync("/api/v1/accounts/me/two-factor/disable", new PasswordConfirmation("Wrong-password-1"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, wrong.StatusCode);
        var login = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, login.StatusCode); // the code is asked for again: still on
        Assert.Contains("two_factor_required", await login.Content.ReadAsStringAsync(Ct));
    }

    [Fact]
    public async Task Refresh_ShouldIssueANewPair_WhenTheTokenIsValid()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, refresh) = await LoginAsync(api);

        var response = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(refresh), Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        Assert.False(string.IsNullOrEmpty(json.RootElement.GetProperty("accessToken").GetString()));
        Assert.False(string.IsNullOrEmpty(json.RootElement.GetProperty("refreshToken").GetString()));
    }

    [Fact]
    public async Task Refresh_ShouldBeRefused_WhenAnAdminLockedTheAccount()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var (_, refresh) = await LoginAsync(api, email, TestApi.MemberPassword);
        await using var scope = api.Services.CreateAsyncScope();
        var member = await scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.Identity.UserManager<User>>().FindByEmailAsync(email);

        var lockResponse = await (await AdminAsync(api)).PostAsync($"/api/v1/admin/users/{member!.Id}/lock", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, lockResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(refresh), Ct)).StatusCode);
    }

    private static Task<HttpClient> AdminAsync(TestApi api) => api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private static async Task<(HttpClient Client, string Key, string[] Codes)> EnableAsync(TestApi api, string? email = null, string? password = null)
    {
        var access = email is null
            ? (await LoginAsync(api)).Access
            : (await LoginAsync(api, email, password ?? TestApi.MemberPassword)).Access;
        var client = WithToken(api, access);
        var setup = await (await client.PostAsync("/api/v1/accounts/me/two-factor/start", null, Ct))
            .Content.ReadFromJsonAsync<TwoFactorSetup>(Ct);
        var enabled = await client.PostAsJsonAsync("/api/v1/accounts/me/two-factor/enable",
            new EnableTwoFactorRequest(password ?? TestApi.AdminPassword, Totp.Code(setup!.Key, DateTimeOffset.UtcNow)), Ct);
        enabled.EnsureSuccessStatusCode();
        var codes = await enabled.Content.ReadFromJsonAsync<RecoveryCodesResponse>(Ct);
        return (client, setup.Key, codes!.RecoveryCodes);
    }
}
