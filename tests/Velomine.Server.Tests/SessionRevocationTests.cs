using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>
/// What a security change ends: a revoked session, a second factor, and every other device. A member who loses a
/// phone or a password must be able to get everyone else out.
/// </summary>
public sealed class SessionRevocationTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(string Access, string Refresh)> LoginAsync(
        TestApi api, string email = TestApi.AdminEmail, string password = TestApi.AdminPassword, string? label = "Phone")
    {
        var response = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(email, password, DeviceLabel: label), Ct);
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
    public async Task RevokeSession_ShouldStopTheCookieAtItsNextCheck_WhenTheSessionIsEnded()
    {
        await using var api = await TestApi.StartAsync(postgres);
        // The browser signs in with a cookie; the phone then ends that same session from its own list.
        var web = await LoginCookiesAsync(api);
        Assert.Equal(HttpStatusCode.OK, (await web.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
        var sessions = await web.GetFromJsonAsync<SessionResponse[]>("/api/v1/accounts/me/sessions", Ct);
        var cookieSession = Assert.Single(sessions!, s => s.Current);

        Assert.Equal(HttpStatusCode.NoContent, (await web.DeleteAsync($"/api/v1/accounts/me/sessions/{cookieSession.Id}", Ct)).StatusCode);

        // A cookie is revalidated at most every five minutes; the session check runs at the next one, so shorten it.
        await using (var scope = api.Services.CreateAsyncScope())
            await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().Database.ExecuteSqlRawAsync(
                "UPDATE accounts.user_sessions SET last_used_at = last_used_at", Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, (await web.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
    }

    [Fact]
    public async Task PasswordReset_ShouldEndEverySession_WhenThePasswordIsReset()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var first = await LoginAsync(api, email, TestApi.MemberPassword);
        var second = await LoginAsync(api, email, TestApi.MemberPassword, "Tablet");

        var change = await WithToken(api, first.Access).PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest(TestApi.MemberPassword, "Another-password-1"), Ct);

        Assert.Equal(HttpStatusCode.NoContent, change.StatusCode);
        // Both phones are out: even the one that made the change cannot refresh.
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(first.Refresh), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(second.Refresh), Ct)).StatusCode);
    }

    [Fact]
    public async Task AdminTwoFactorReset_ShouldEndEverySessionOfThatAccount_WhenItIsReset()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        // A member with two devices and their second factor on; an admin resets the factor.
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var first = await LoginAsync(api, email, TestApi.MemberPassword);
        var second = await LoginAsync(api, email, TestApi.MemberPassword, "Tablet");
        await EnableAsync(api, email, TestApi.MemberPassword);
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.Identity.UserManager<User>>();
        var member = await users.FindByEmailAsync(email);

        var reset = await (await AdminAsync(api)).PostAsync($"/api/v1/admin/users/{member!.Id}/two-factor/reset", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        // The reset revokes every session: neither refresh token works any more.
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(first.Refresh), Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(second.Refresh), Ct)).StatusCode);
    }

    [Fact]
    public async Task EnableTwoFactor_ShouldSignOutTheOtherDevices_WhenItIsTurnedOn()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        await LoginAsync(api, email, TestApi.MemberPassword, "Old phone");

        await EnableAsync(api, email, TestApi.MemberPassword);

        await using var scope = api.Services.CreateAsyncScope();
        var alive = await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().UserSessions.AsNoTracking()
            .Where(s => s.Label == "Old phone" && s.RevokedAt == null).CountAsync(Ct);
        Assert.Equal(0, alive);
    }

    [Fact]
    public async Task DisableTwoFactor_ShouldBeRefused_WhenThePasswordIsWrong()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (client, _, _) = await EnableAsync(api);

        var wrong = await client.PostAsJsonAsync("/api/v1/accounts/me/two-factor/disable", new PasswordConfirmation("Wrong-password-1"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, wrong.StatusCode);
        var login = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        Assert.Equal(HttpStatusCode.Accepted, login.StatusCode); // the code is asked for again: still on
        Assert.True((await login.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct))!.TwoFactorRequired);
    }

    private static Task<HttpClient> AdminAsync(TestApi api) => api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private static async Task<HttpClient> LoginCookiesAsync(TestApi api)
    {
        var client = api.CreateClient(handleCookies: true);
        var response = await client.PostAsJsonAsync("/api/v1/accounts/login",
            new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword, UseCookies: true), Ct);
        response.EnsureSuccessStatusCode();
        return client;
    }

    private static async Task<(HttpClient Client, string Key, string[] Codes)> EnableAsync(TestApi api, string? email = null, string? password = null)
    {
        var access = email is null
            ? (await LoginAsync(api)).Access
            : (await LoginAsync(api, email, password ?? TestApi.MemberPassword, "Phone")).Access;
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
