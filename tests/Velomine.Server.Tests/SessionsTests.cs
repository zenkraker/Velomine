using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

public sealed class SessionsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(string Access, string Refresh)> LoginAsync(
        TestApi api,
        string email = TestApi.AdminEmail,
        string password = TestApi.AdminPassword,
        string? label = "Android app")
    {
        var response = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login",
            new LoginRequest(email, password, DeviceLabel: label),
            Ct);
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

    private static Task<HttpResponseMessage> RefreshAsync(TestApi api, string refreshToken) =>
        api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh", new RefreshRequest(refreshToken), Ct);

    [Fact]
    public async Task Sessions_ShouldListTheCurrentSession_WhenTheMemberSignsIn()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (access, _) = await LoginAsync(api);

        var rows = await WithToken(api, access).GetFromJsonAsync<SessionResponse[]>("/api/v1/accounts/me/sessions", Ct);

        var row = Assert.Single(rows!);
        Assert.True(row.Current);
        Assert.Equal("Android app", row.Label);
    }

    [Fact]
    public async Task Sessions_ShouldBelongToTheirMember_WhenAnotherMemberTriesToRevokeThem()
    {
        await using var api = await TestApi.StartAsync(postgres,
            b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var otherEmail = TestApi.NewEmail();
        (await api.RegisterAsync(otherEmail)).EnsureSuccessStatusCode();
        var mine = await LoginAsync(api);
        var theirs = await LoginAsync(api, otherEmail, TestApi.MemberPassword);
        var theirSession = Assert.Single((await WithToken(api, theirs.Access)
            .GetFromJsonAsync<SessionResponse[]>("/api/v1/accounts/me/sessions", Ct))!);

        var response = await WithToken(api, mine.Access).DeleteAsync($"/api/v1/accounts/me/sessions/{theirSession.Id}", Ct);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        // Refreshing proves the session is still there: a revoked one is refused.
        Assert.Equal(HttpStatusCode.OK, (await RefreshAsync(api, theirs.Refresh)).StatusCode);
    }

    [Fact]
    public async Task RevokeSession_ShouldEndOnlyThatSession_WhenTheMemberAsks()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var first = await LoginAsync(api);
        var second = await LoginAsync(api, label: "Web - Chrome");
        var client = WithToken(api, second.Access);
        var rows = await client.GetFromJsonAsync<SessionResponse[]>("/api/v1/accounts/me/sessions", Ct);
        var other = rows!.Single(r => !r.Current);

        Assert.Equal(HttpStatusCode.NoContent, (await client.DeleteAsync($"/api/v1/accounts/me/sessions/{other.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(api, first.Refresh)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await RefreshAsync(api, second.Refresh)).StatusCode);
    }

    [Fact]
    public async Task LogoutOthers_ShouldKeepTheCurrentSession_WhenItIsCalled()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var first = await LoginAsync(api);
        var second = await LoginAsync(api);
        var client = WithToken(api, second.Access);

        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsync("/api/v1/accounts/me/sessions/logout-others", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(api, first.Refresh)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await RefreshAsync(api, second.Refresh)).StatusCode);
    }

    [Fact]
    public async Task Refresh_ShouldRotateTheRefreshToken_WhenTheSessionIsValid()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, refresh) = await LoginAsync(api);

        var response = await RefreshAsync(api, refresh);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        Assert.NotEqual(refresh, json.RootElement.GetProperty("refreshToken").GetString());
    }

    [Fact]
    public async Task Refresh_ShouldRevokeTheSession_WhenAnOldRefreshTokenIsReused()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, refresh) = await LoginAsync(api);
        var first = await RefreshAsync(api, refresh);
        using var json = JsonDocument.Parse(await first.Content.ReadAsStringAsync(Ct));
        var rotated = json.RootElement.GetProperty("refreshToken").GetString()!;

        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(api, refresh)).StatusCode);
        // The session is treated as stolen, so the legitimate new token stops working too.
        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(api, rotated)).StatusCode);
    }

    [Fact]
    public async Task Logout_ShouldRevokeTheSession_WhenCalledFromThePhone()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (access, refresh) = await LoginAsync(api);

        Assert.Equal(HttpStatusCode.NoContent, (await WithToken(api, access).PostAsync("/api/v1/accounts/logout", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(api, refresh)).StatusCode);
    }

}
