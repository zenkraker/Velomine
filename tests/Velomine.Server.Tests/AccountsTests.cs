using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class AccountsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task NewAccount_CannotSignInUntilAnAdminApprovesIt()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var email = TestApi.NewEmail();

        var registered = await api.RegisterAsync(email);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        var account = await registered.Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        Assert.False(account!.IsApproved);

        Assert.Equal(HttpStatusCode.Forbidden, (await api.LoginAsync(email, TestApi.MemberPassword)).StatusCode);

        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var pending = await admin.GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users?pending=true", Ct);
        Assert.Contains(pending!, u => u.Email == email);

        Assert.Equal(HttpStatusCode.NoContent, (await admin.PostAsync($"/api/v1/accounts/users/{account.Id}/approve", null, Ct)).StatusCode);

        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        var me = await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal(email, me!.Email);
        Assert.Equal(["member"], me.Roles);
    }

    [Fact]
    public async Task Admin_FromConfiguration_HasAdminAndMemberRoles()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var me = await admin.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        Assert.Equal(["admin", "member"], me!.Roles.Order());
    }

    [Fact]
    public async Task Register_WithAWeakPassword_IsRejected()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.RegisterAsync(TestApi.NewEmail(), password: "short");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithATakenEmail_IsRejected()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var email = TestApi.NewEmail();
        await api.RegisterAsync(email);

        var again = await api.RegisterAsync(email);

        Assert.Equal(HttpStatusCode.BadRequest, again.StatusCode);
    }

    [Fact]
    public async Task Register_WhenSignUpIsOff_IsForbidden()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:SignUpEnabled", "false"));

        var response = await api.RegisterAsync(TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithoutSigningIn_IsUnauthorized()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.CreateClient().GetAsync("/api/v1/accounts/me", Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Member_CannotManageUsers()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        await api.RegisterAsync(email);
        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);

        var response = await member.GetAsync("/api/v1/accounts/users", Ct);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task WrongPassword_IsUnauthorized_AndRepeatedFailuresLockTheAccount()
    {
        await using var api = await TestApi.StartAsync(postgres);

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.LoginAsync(TestApi.AdminEmail, "Wrong-password-1")).StatusCode);
        for (var i = 0; i < 4; i++) await api.LoginAsync(TestApi.AdminEmail, "Wrong-password-1");

        var locked = await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Equal((HttpStatusCode)423, locked.StatusCode);
    }

    [Fact]
    public async Task RefreshToken_GivesNewTokens()
    {
        await using var api = await TestApi.StartAsync(postgres);
        using var login = JsonDocument.Parse(await (await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword)).Content.ReadAsStringAsync(Ct));

        var refreshed = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/refresh",
            new RefreshRequest(login.RootElement.GetProperty("refreshToken").GetString()!),
            Ct);

        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
        using var tokens = JsonDocument.Parse(await refreshed.Content.ReadAsStringAsync(Ct));
        Assert.False(string.IsNullOrEmpty(tokens.RootElement.GetProperty("accessToken").GetString()));
    }

    [Fact]
    public async Task RefreshToken_Garbage_IsUnauthorized()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var response = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest("not-a-token"), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CookieSession_WorksForTheWebApp_AndLogoutEndsIt()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var web = api.CreateClient(handleCookies: true);

        var login = await web.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword, UseCookies: true), Ct);
        Assert.Equal(HttpStatusCode.NoContent, login.StatusCode); // the session is in the cookie, there is no body
        Assert.Equal(HttpStatusCode.OK, (await web.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);

        await web.PostAsync("/api/v1/accounts/logout", null, Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, (await web.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
    }
}
