using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

public sealed class TwoFactorTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static HttpClient WithToken(TestApi api, string token)
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    private static async Task<string> AccessTokenAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        return json.RootElement.GetProperty("accessToken").GetString()!;
    }

    private static async Task<(HttpClient Client, string Key, string[] Codes)> EnableAsync(TestApi api)
    {
        var client = WithToken(api, await AccessTokenAsync(api.CreateClient()));
        var setup = await (await client.PostAsync("/api/v1/accounts/me/two-factor/start", null, Ct))
            .Content.ReadFromJsonAsync<TwoFactorSetup>(Ct);
        var enabled = await client.PostAsJsonAsync(
            "/api/v1/accounts/me/two-factor/enable",
            new EnableTwoFactorRequest(TestApi.AdminPassword, Totp.Code(setup!.Key, DateTimeOffset.UtcNow)),
            Ct);
        enabled.EnsureSuccessStatusCode();
        var codes = await enabled.Content.ReadFromJsonAsync<RecoveryCodesResponse>(Ct);
        return (client, setup.Key, codes!.RecoveryCodes);
    }

    [Fact]
    public async Task TwoFactor_ShouldAskForACode_WhenItIsEnabled()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, key, codes) = await EnableAsync(api);
        Assert.Equal(10, codes.Length);

        var login = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login",
            new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword),
            Ct);

        Assert.Equal(HttpStatusCode.Accepted, login.StatusCode);
        var required = await login.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct);
        Assert.True(required!.TwoFactorRequired);

        var second = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login/two-factor",
            new LoginTwoFactorRequest(required.Challenge, Totp.Code(key, DateTimeOffset.UtcNow), DeviceLabel: "iPhone app"),
            Ct);

        Assert.Equal(HttpStatusCode.OK, second.StatusCode);
        using var json = JsonDocument.Parse(await second.Content.ReadAsStringAsync(Ct));
        Assert.False(string.IsNullOrEmpty(json.RootElement.GetProperty("accessToken").GetString()));
    }

    [Fact]
    public async Task TwoFactor_ShouldRefuseTheCode_WhenItIsWrong()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, key, _) = await EnableAsync(api);

        var login = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        var required = await login.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct);
        var valid = Totp.Code(key, DateTimeOffset.UtcNow);
        var wrong = (char)('0' + (valid[0] - '0' + 1) % 10) + valid[1..];

        var second = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login/two-factor",
            new LoginTwoFactorRequest(required!.Challenge, wrong),
            Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, second.StatusCode);
    }

    [Fact]
    public async Task TwoFactor_ShouldAcceptARecoveryCodeOnlyOnce()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (_, _, codes) = await EnableAsync(api);

        var first = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        var firstRequired = await first.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct);
        Assert.Equal(HttpStatusCode.OK, (await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login/two-factor",
            new LoginTwoFactorRequest(firstRequired!.Challenge, codes[0]),
            Ct)).StatusCode);

        var second = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        var secondRequired = await second.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login/two-factor",
            new LoginTwoFactorRequest(secondRequired!.Challenge, codes[0]),
            Ct)).StatusCode);
    }

    [Fact]
    public async Task EnableTwoFactor_ShouldRefuse_WhenThePasswordIsWrong()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var client = WithToken(api, await AccessTokenAsync(api.CreateClient()));
        var setup = await (await client.PostAsync("/api/v1/accounts/me/two-factor/start", null, Ct))
            .Content.ReadFromJsonAsync<TwoFactorSetup>(Ct);

        var response = await client.PostAsJsonAsync(
            "/api/v1/accounts/me/two-factor/enable",
            new EnableTwoFactorRequest("Wrong-password-1", Totp.Code(setup!.Key, DateTimeOffset.UtcNow)),
            Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TwoFactor_ShouldStopAsking_WhenAnAdminResetsIt()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (client, _, _) = await EnableAsync(api);
        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        var reset = await client.PostAsync($"/api/v1/admin/users/{me!.Id}/two-factor/reset", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        var login = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
    }

    [Fact]
    public async Task TwoFactor_ShouldTurnOff_WhenThePasswordIsConfirmed()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var (client, _, _) = await EnableAsync(api);
        // Enabling signs other devices out; this one is still valid.
        var disable = await client.PostAsJsonAsync("/api/v1/accounts/me/two-factor/disable", new PasswordConfirmation(TestApi.AdminPassword), Ct);

        Assert.Equal(HttpStatusCode.NoContent, disable.StatusCode);
        var login = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest(TestApi.AdminEmail, TestApi.AdminPassword), Ct);
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
    }

}
